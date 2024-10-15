import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore importálása
import '../main.dart'; // Importáljuk a login_screen fájlt, hogy oda irányítsuk vissza a felhasználót
import 'favorite_workouts_screen.dart'; // Importáljuk a kedvenc edzések képernyőt

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user = FirebaseAuth.instance.currentUser;

  // Firestore-ból adat lekérő függvény
  Future<Map<String, dynamic>?> getUserData() async {
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  Future<void> _deleteAccount() async {
    // Megerősítés kérdése a felhasználótól
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete) {
      try {
        // Törlés a Firestore 'users' gyűjteményéből
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .delete();

        // Felhasználó törlése a Firebase Authentication-ből
        await user!.delete();

        // Kijelentkezés és átirányítás a bejelentkezési oldalra
        await FirebaseAuth.instance.signOut();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Your account has been successfully deleted.')),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Please log in again to confirm account deletion.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.message}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: getUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return const Text('Error loading user data');
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return const Text('No user data found');
            }

            Map<String, dynamic> userData = snapshot.data!;
            String email = user?.email ?? 'N/A';
            int weight = userData['weight'] ?? 0;
            int completedWorkouts = userData['completedWorkouts'] ?? 0;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Welcome, $email",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  "Weight: $weight kg",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  "Completed Workouts: $completedWorkouts",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const FavoriteWorkoutsScreen(),
                      ),
                    );
                  },
                  child: const Text("Favorite Workouts"),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text("Log Out"),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _deleteAccount, // Felhasználói fiók törlése
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Delete Account"),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
