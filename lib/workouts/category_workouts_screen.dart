import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Felhasználó ellenőrzéséhez
import 'workout_detail_screen.dart';
import 'add_workout_screen.dart'; // Az új edzés hozzáadásának képernyője

class CategoryWorkoutsScreen extends StatefulWidget {
  final String category;

  const CategoryWorkoutsScreen({super.key, required this.category});

  @override
  _CategoryWorkoutsScreenState createState() => _CategoryWorkoutsScreenState();
}

class _CategoryWorkoutsScreenState extends State<CategoryWorkoutsScreen> {
  String? userRole;

  @override
  void initState() {
    super.initState();
    _getCurrentUserRole();
  }

  // Felhasználó szerepkörének lekérdezése Firestore-ból
  Future<void> _getCurrentUserRole() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      setState(() {
        userRole = userDoc['role'];
      });
    }
  }

  Stream<List<Map<String, dynamic>>> getWorkoutsByCategory() {
    return FirebaseFirestore.instance
        .collection('workouts')
        .where('category', isEqualTo: widget.category)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              Map<String, dynamic> workoutData =
                  doc.data() as Map<String, dynamic>;
              workoutData['id'] =
                  doc.id; // Hozzáadjuk a dokumentum ID-ját az edzés adataihoz
              return workoutData;
            }).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category} Workouts'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getWorkoutsByCategory(),
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
      floatingActionButton: userRole == 'admin'
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        AddWorkoutScreen(category: widget.category),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
