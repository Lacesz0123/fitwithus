import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'workout_detail_screen.dart';

class CategoryWorkoutsScreen extends StatelessWidget {
  final String category;

  const CategoryWorkoutsScreen({super.key, required this.category});

  Future<List<Map<String, dynamic>>> getWorkoutsByCategory() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('workouts')
        .where('category', isEqualTo: category)
        .get();

    // Minden edzés adatait listává alakítjuk és hozzáadjuk a Firestore dokumentum ID-ját
    return querySnapshot.docs.map((doc) {
      Map<String, dynamic> workoutData = doc.data() as Map<String, dynamic>;
      workoutData['id'] =
          doc.id; // Hozzáadjuk a dokumentum ID-ját az edzés adataihoz
      return workoutData;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$category Workouts'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getWorkoutsByCategory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading workouts'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No workouts found for this category'));
          }

          List<Map<String, dynamic>> workouts = snapshot.data!;

          return ListView.builder(
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> workout = workouts[index];
              String workoutTitle = workout['title'] ?? 'No title';
              String workoutDescription =
                  workout['description'] ?? 'No description';

              return ListTile(
                title: Text(workoutTitle),
                subtitle: Text(workoutDescription),
                onTap: () {
                  // Navigálás az edzés részletező oldalra
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => WorkoutDetailScreen(
                        workoutId: workout['id'], // Az edzés azonosítója
                      ),
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
