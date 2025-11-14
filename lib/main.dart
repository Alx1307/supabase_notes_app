import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_gate.dart';
import 'notes_page.dart';

const supabaseUrl = 'https://wgodaryaxmyqpihinxqb.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indnb2RhcnlheG15cXBpaGlueHFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMxMjY5OTMsImV4cCI6MjA3ODcwMjk5M30.UDU0yOB9vF9_olWOBmVrk7qJuIj1bxj99JazOoqlS8w';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Notes',
      theme: ThemeData(useMaterial3: true),
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = snapshot.data?.session;
          if (session == null) {
            return const AuthGate();
          } else {
            return const NotesPage();
          }
        },
      ),
    );
  }
}