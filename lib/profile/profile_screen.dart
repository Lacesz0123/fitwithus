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
      // Lekérjük a felhasználó adatait az 'users' gyűjteményből a felhasználó UID-ja alapján
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: getUserData(), // Lekérjük a Firestore adatokat
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(); // Betöltés jelzése
            }
            if (snapshot.hasError) {
              return const Text('Error loading user data'); // Hiba esetén
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Text('No user data found'); // Ha nincs adat
            }

            // Lekérjük az adatokat a Firestore-ból
            Map<String, dynamic> userData = snapshot.data!;
            String email = user?.email ?? 'N/A';
            int weight = userData['weight'] ?? 0; // Súly
            int completedWorkouts =
                userData['completedWorkouts'] ?? 0; // Completed Workouts

            // Adatok megjelenítése
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Welcome, $email", // Email megjelenítése
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Weight: $weight kg", // Súly megjelenítése
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Completed Workouts: $completedWorkouts", // Teljesített edzések
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Navigáció a Kedvenc edzések képernyőre
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const FavoriteWorkoutsScreen()),
                    );
                  },
                  child: const Text(
                      "Favorite Workouts"), // Gomb a Kedvenc edzésekhez
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    // Firebase kijelentkezés
                    await FirebaseAuth.instance.signOut();
                    // Átirányítás a bejelentkezési oldalra
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text("Log Out"), // Kijelentkezés gomb
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
