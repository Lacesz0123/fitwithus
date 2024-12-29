import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'workout_detail_screen.dart';
import 'add_workout_screen.dart';
import 'edit_workout_screen.dart';

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
              Map<String, dynamic> workoutData = doc.data();
              workoutData['id'] = doc.id;
              return workoutData;
            }).toList());
  }

  void editWorkout(BuildContext context, Map<String, dynamic> workout) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditWorkoutScreen(
          workoutId: workout['id'],
          initialTitle: workout['title'] ?? 'No title',
          initialDescription: workout['description'] ?? 'No description',
          initialSteps: List<String>.from(workout['steps'] ?? []),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category} Workouts'),
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
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: getWorkoutsByCategory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Hiba az edzések betöltése közben'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('Nincs ilyen kategóriába tartozó edzés'));
                }

                List<Map<String, dynamic>> workouts = snapshot.data!;

                return ListView.builder(
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> workout = workouts[index];
                    String workoutTitle = workout['title'] ?? 'Nincs cím';
                    String workoutDescription =
                        workout['description'] ?? 'Nincs leírás';

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => WorkoutDetailScreen(
                              workoutId: workout['id'],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
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
                                      color: Colors.teal,
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
                                ],
                              ),
                            ),
                            if (userRole == 'admin')
                              IconButton(
                                icon: const Icon(
                                  Icons.settings,
                                  color: Colors.blueAccent,
                                ),
                                onPressed: () => editWorkout(context, workout),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (userRole == 'admin')
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            AddWorkoutScreen(category: widget.category),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add New',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
