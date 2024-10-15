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
              String workoutId = workout['id'];

              return ListTile(
                title: Text(workoutTitle),
                onTap: () {
                  // Navigálás az edzés részletező oldalra
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          WorkoutDetailScreen(workoutId: workoutId),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
