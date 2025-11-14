import 'package:flutter/material.dart';
import 'models/note.dart';

const Color primaryColor = Color.fromARGB(255, 52, 178, 123);
const Color secondaryColor = Color.fromARGB(255, 248, 249, 250);

class EditNotePage extends StatefulWidget {
  final Note? existing;
  const EditNotePage({super.key, this.existing});

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _bodyController = TextEditingController(text: widget.existing?.body ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final now = DateTime.now();

    final result = (widget.existing == null)
      ? Note(
          id: '',
          title: title,
          body: body,
          createdAt: now,
          updatedAt: now,
        )
      : widget.existing!.copyWith(
          title: title, 
          body: body,
          updatedAt: now,
        );
    
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: secondaryColor),
        title: Text(
          isEdit ? 'Редактировать' : 'Новая заметка',
          style: TextStyle(
            color: secondaryColor,
            fontSize: 30,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Заголовок',
                  labelStyle: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyController,
                decoration: InputDecoration(
                  labelText: 'Текст',
                  labelStyle: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: const Color.fromARGB(255, 179, 19, 8)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: const Color.fromARGB(255, 179, 19, 8)),
                  ),
                  errorStyle: TextStyle(
                    color: const Color.fromARGB(255, 179, 19, 8),
                  ),
                ),
                minLines: 1,
                maxLines: 15,
                validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Введите текст заметки'
                  : null,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _save,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(primaryColor),
                  minimumSize: WidgetStateProperty.all<Size>(const Size(200, 60)),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  elevation: WidgetStateProperty.all<double>(5),
                  shadowColor: WidgetStateProperty.all<Color>(Color.fromRGBO(0, 0, 0, 0.9)),
                ),
                icon: const Icon(
                  Icons.check,
                  size: 30
                ),
                label: const Text(
                  'Сохранить',
                  style: TextStyle(
                    fontSize: 20
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}