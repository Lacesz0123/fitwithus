import 'package:flutter/material.dart';

import 'screens/login_screen.dart'; // <- LoginScreen import
import 'services/firebase_init.dart'; // <- FirebaseInitializer import

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitWithUs',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Roboto',
            letterSpacing: 1.2,
          ),
          backgroundColor: Colors.blueAccent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        primarySwatch: Colors.blue,
      ),
      home: const LoadingScreen(),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: FirebaseInitializer.init(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return const LoginScreen();
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
