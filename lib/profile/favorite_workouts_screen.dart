import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '/workouts/workout_detail_screen.dart'; // Importáljuk az edzés részletező képernyőt

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
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3), // Árnyék pozíciója
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workoutTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Category: $workoutCategory',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
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
