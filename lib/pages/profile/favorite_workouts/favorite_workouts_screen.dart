import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../workouts/in_a_category/workout_detail_screen.dart';

/// A [FavoriteWorkoutsScreen] képernyő megjeleníti a felhasználó kedvenc edzéseit.
///
/// ## Funkciók:
/// - Lekérdezi a bejelentkezett felhasználó `favorites` listáját a Firestore-ból.
/// - Betölti a hozzátartozó `workouts` dokumentumokat.
/// - Megjeleníti őket egy listában, kártyás stílusban.
/// - Az egyes elemekre kattintva navigál a [WorkoutDetailScreen]-re.
///
/// ## Technikai megvalósítás:
/// - A kedvencek `users/{uid}/favorites` tömbben vannak tárolva (edzésdokumentum-azonosítók).
/// - A lekérdezés `FutureBuilder`-en keresztül történik.
/// - Támogatja a sötét és világos témát (`Theme.of(context).brightness` alapján).
///
/// ## Megjelenítés:
/// - Minden edzést kártyaformában jelenít meg: cím, leírás és kategória.
/// - A listanézet görgethető, és alapértelmezett üzenetet jelenít meg, ha nincsenek kedvencek.
class FavoriteWorkoutsScreen extends StatelessWidget {
  const FavoriteWorkoutsScreen({super.key});

  Future<List<Map<String, dynamic>>> getFavoriteWorkouts() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      List<dynamic> favoriteWorkoutIds = userDoc['favorites'] ?? [];

      List<Map<String, dynamic>> favoriteWorkouts = [];
      for (var workoutId in favoriteWorkoutIds) {
        DocumentSnapshot workoutDoc = await FirebaseFirestore.instance
            .collection('workouts')
            .doc(workoutId)
            .get();
        if (workoutDoc.exists) {
          Map<String, dynamic> workoutData =
              workoutDoc.data() as Map<String, dynamic>;
          workoutData['id'] = workoutId;
          favoriteWorkouts.add(workoutData);
        }
      }
      return favoriteWorkouts;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final cardShadow =
        isDark ? Colors.transparent : Colors.grey.withOpacity(0.3);
    final titleColor = isDark ? Colors.grey.shade100 : Colors.blueAccent;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Workouts'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : null,
            gradient: !isDark
                ? const LinearGradient(
                    colors: [Colors.blueAccent, Colors.tealAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getFavoriteWorkouts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No favorite workouts',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            );
          }

          List<Map<String, dynamic>> favoriteWorkouts = snapshot.data!;
          return ListView.builder(
            itemCount: favoriteWorkouts.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> workout = favoriteWorkouts[index];
              String workoutTitle = workout['title'] ?? 'No title';
              String workoutCategory =
                  workout['category'] ?? 'Unknown category';
              String workoutDescription =
                  workout['description'] ?? 'No description';
              String workoutId = workout['id'];

              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          WorkoutDetailScreen(workoutId: workoutId),
                    ),
                  );
                },
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: cardShadow,
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workoutTitle,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              workoutDescription,
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Category: $workoutCategory',
                              style: TextStyle(
                                fontSize: 14,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
