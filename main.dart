import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart'; // `flutterfire configure` buyrug'i yaratadi
import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase-ni ishga tushiramiz
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const QarzDaftarApp());
}

class QarzDaftarApp extends StatelessWidget {
  const QarzDaftarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qarz Daftar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const AuthGate(),
    );
  }
}
