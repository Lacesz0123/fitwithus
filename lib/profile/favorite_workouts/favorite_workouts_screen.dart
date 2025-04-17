import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../workouts/in_a_category/workout_detail_screen.dart';

class FavoriteWorkoutsScreen extends StatelessWidget {
  const FavoriteWorkoutsScreen({super.key});

  // Kedvenc edzések lekérése a Firestore-ból
  Future<List<Map<String, dynamic>>> getFavoriteWorkouts() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      List<dynamic> favoriteWorkoutIds = userDoc['favorites'] ?? [];

      // Lekérjük az edzések részleteit az ID alapján
      List<Map<String, dynamic>> favoriteWorkouts = [];
      for (var workoutId in favoriteWorkoutIds) {
        DocumentSnapshot workoutDoc = await FirebaseFirestore.instance
            .collection('workouts')
            .doc(workoutId)
            .get();
        if (workoutDoc.exists) {
          Map<String, dynamic> workoutData =
              workoutDoc.data() as Map<String, dynamic>;
          workoutData['id'] = workoutId; // ID hozzáadása
          favoriteWorkouts.add(workoutData);
        }
      }
      return favoriteWorkouts;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Workouts'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.tealAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
            return const Center(child: Text('No favorite workouts'));
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
                  // Navigálás az edzés részletező oldalra
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
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
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              workoutDescription,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Category: $workoutCategory',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
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
