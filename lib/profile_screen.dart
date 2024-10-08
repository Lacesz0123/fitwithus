import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'main.dart'; // Importáljuk a login_screen fájlt, hogy oda irányítsuk vissza a felhasználót

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Welcome to your profile"),
            const SizedBox(height: 20),
            // Kijelentkezés gomb
            ElevatedButton(
              onPressed: () async {
                // Firebase kijelentkezés
                await FirebaseAuth.instance.signOut();
                // Átirányítás a bejelentkezési felületre
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text("Log Out"),
            ),
          ],
        ),
      ),
    );
  }
}
