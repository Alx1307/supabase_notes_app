import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/note.dart';
import 'edit_note_page.dart';
import 'auth_gate.dart';
import 'dart:async';

final supabase = Supabase.instance.client;

const Color primaryColor = Color.fromARGB(255, 52, 178, 123);
const Color secondaryColor = Color.fromARGB(255, 248, 249, 250);

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;
  Stream<List<Map<String, dynamic>>>? _notesStream;
  final _streamController = StreamController<List<Map<String, dynamic>>>.broadcast();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _initializeStream();
  }

  void _initializeStream() {
    final uid = supabase.auth.currentUser!.id;
    _notesStream = supabase
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('updated_at', ascending: false);
    
    _notesStream?.listen((data) {
      if (!_streamController.isClosed) {
        _streamController.add(data);
      }
    });
  }

  void _refreshStream() {
    final uid = supabase.auth.currentUser!.id;
    supabase
        .from('notes')
        .select()
        .eq('user_id', uid)
        .order('updated_at', ascending: false)
        .then((data) {
      if (!_streamController.isClosed) {
        _streamController.add(data);
      }
    });
  }

  Stream<List<Note>> _getNotesStream() {
    return _streamController.stream.map((list) => list
        .map((data) => Note(
              id: data['id'].toString(),
              title: data['title'] ?? '',
              body: data['content'] ?? '',
              createdAt: DateTime.parse(data['created_at']),
              updatedAt: DateTime.parse(data['updated_at']),
            ))
        .toList());
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка выхода: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _streamController.close();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {});
    });
  }

  Future<void> _addNote() async {
    final newNote = await Navigator.push<Note>(
      context,
      MaterialPageRoute(builder: (_) => const EditNotePage()),
    );
    if (newNote != null) {
      final uid = supabase.auth.currentUser!.id;
      await supabase.from('notes').insert({
        'user_id': uid,
        'title': newNote.title,
        'content': newNote.body,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      _refreshStream();
    }
  }

  Future<void> _edit(Note note) async {
    final updated = await Navigator.push<Note>(
      context,
      MaterialPageRoute(builder: (_) => EditNotePage(existing: note)),
    );
    if (updated != null) {
      await supabase.from('notes').update({
        'title': updated.title,
        'content': updated.body,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', note.id);
      
      _refreshStream();
    }
  }

  Future<void> _delete(Note note) async {
    final removedNote = note;
    
    await supabase.from('notes').delete().eq('id', note.id);

    _refreshStream();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Заметка удалена',
          textAlign: TextAlign.center,
        ),
        action: SnackBarAction(
          label: 'Отменить',
          textColor: secondaryColor,
          onPressed: () async {
            final uid = supabase.auth.currentUser!.id;
            await supabase.from('notes').insert({
              'id': removedNote.id,
              'user_id': uid,
              'title': removedNote.title,
              'content': removedNote.body,
              'created_at': removedNote.createdAt.toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
            
            _refreshStream();
          },
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        backgroundColor: primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: primaryColor,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Поиск по заголовкам...',
                  hintStyle: TextStyle(color: Color.fromRGBO(255, 251, 245, 0.7)),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: secondaryColor, fontSize: 18),
                cursorColor: secondaryColor,
              )
            : const Text(
                'Supabase Notes',
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: 30,
                ),
              ),
        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: secondaryColor,
              size: 28,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: secondaryColor),
            onPressed: _signOut,
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 60,
        height: 60,
        child: FloatingActionButton(
          onPressed: _addNote,
          backgroundColor: primaryColor,
          foregroundColor: secondaryColor,
          child: const Icon(
            Icons.add,
            size: 40,
          ),
        ),
      ),
      body: StreamBuilder<List<Note>>(
        stream: _getNotesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ошибка загрузки: ${snapshot.error}',
                style: const TextStyle(fontSize: 24),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final allNotes = snapshot.data!;
          
          final displayedNotes = _searchController.text.isEmpty
              ? allNotes
              : allNotes.where((note) => 
                  note.title.toLowerCase().contains(_searchController.text.toLowerCase()))
                  .toList();

          if (displayedNotes.isEmpty) {
            return Center(
              child: Text(
                _searchController.text.isNotEmpty 
                    ? 'Ничего не найдено' 
                    : 'Пока нет заметок. Нажмите +',
                style: const TextStyle(
                  fontSize: 24,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: displayedNotes.length,
            itemBuilder: (context, i) {
              final note = displayedNotes[i];
              
              return Dismissible(
                key: ValueKey(note.id + (_isSearching ? '_search' : '_normal')),
                direction: DismissDirection.endToStart,
                background: Container(
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 234, 232, 230),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return true;
                },
                onDismissed: (direction) {
                  _delete(note);
                },
                child: SizedBox(
                  height: 100,
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    elevation: 2,
                    child: ListTile(
                      key: ValueKey(note.id),
                      tileColor: secondaryColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      title: Text(
                        note.title.isEmpty ? 'Без названия' : note.title,
                        style: const TextStyle(
                          fontSize: 20,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        note.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color.fromARGB(255, 115, 115, 115),
                        ),
                      ),
                      onTap: () => _edit(note),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: primaryColor,
                          size: 35,
                        ),
                        onPressed: () => _delete(note),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}