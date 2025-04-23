import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final String workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  _WorkoutDetailScreenState createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  bool isFavorite = false;
  double? userRating;
  double averageRating = 0.0;
  bool isGuest = false;

  @override
  void initState() {
    super.initState();
    _checkIfGuest();
    _checkIfFavorite();
    _fetchRatings();
  }

  void _checkIfGuest() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.isAnonymous) {
      setState(() {
        isGuest = true;
      });
    }
  }

  Future<Map<String, dynamic>?> getWorkoutData() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('workouts')
        .doc(widget.workoutId)
        .get();
    return doc.data() as Map<String, dynamic>?;
  }

  Future<void> _checkIfFavorite() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      List<dynamic> favoriteWorkouts =
          (userDoc.data() as Map<String, dynamic>?)?['favorites'] ?? [];

      setState(() {
        isFavorite = favoriteWorkouts.contains(widget.workoutId);
      });
    }
  }

  Future<void> _fetchRatings() async {
    DocumentSnapshot workoutDoc = await FirebaseFirestore.instance
        .collection('workouts')
        .doc(widget.workoutId)
        .get();

    Map<String, dynamic> ratings =
        (workoutDoc.data() as Map<String, dynamic>?)?['ratings'] ?? {};

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null && ratings.containsKey(user.uid)) {
      setState(() {
        userRating = (ratings[user.uid] as num).toDouble();
      });
    }

    if (ratings.isNotEmpty) {
      double totalRating =
          ratings.values.fold(0.0, (sum, value) => sum + (value as num));
      setState(() {
        averageRating = totalRating / ratings.length;
      });
    } else {
      setState(() {
        averageRating = 0.0;
      });
    }
  }

  Future<void> _updateRating(double rating) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    DocumentReference workoutRef =
        FirebaseFirestore.instance.collection('workouts').doc(widget.workoutId);

    DocumentSnapshot workoutDoc = await workoutRef.get();
    Map<String, dynamic> ratings =
        (workoutDoc.data() as Map<String, dynamic>?)?['ratings'] ?? {};

    ratings[user.uid] = rating;

    double totalRating =
        ratings.values.fold(0.0, (sum, value) => sum + (value as num));
    double newAverageRating = totalRating / ratings.length;

    await workoutRef.update({
      'ratings': ratings,
      'averageRating': newAverageRating,
    });

    setState(() {
      userRating = rating;
      averageRating = newAverageRating;
    });
  }

  Future<void> _toggleFavorite() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      DocumentSnapshot userDoc = await userRef.get();
      List<dynamic> favoriteWorkouts =
          (userDoc.data() as Map<String, dynamic>?)?['favorites'] ?? [];

      if (favoriteWorkouts.contains(widget.workoutId)) {
        await userRef.update({
          'favorites': FieldValue.arrayRemove([widget.workoutId])
        });
        setState(() {
          isFavorite = false;
        });
      } else {
        await userRef.update({
          'favorites': FieldValue.arrayUnion([widget.workoutId])
        });
        setState(() {
          isFavorite = true;
        });
      }
    }
  }

  Future<void> _markWorkoutCompleted() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      await userRef.update({
        'completedWorkouts': FieldValue.increment(1),
      });
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Completion'),
          content: const Text(
              'Are you sure you want to mark this workout as completed?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _markWorkoutCompleted();
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Details'),
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
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getWorkoutData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading workout data'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No workout found'));
          }

          Map<String, dynamic> workoutData = snapshot.data!;
          String title = workoutData['title'] ?? 'No Title';
          String description = workoutData['description'] ?? 'No Description';
          List<dynamic> steps = workoutData['steps'] ?? [];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Title + (optional) favorite
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                    if (!isGuest)
                      GestureDetector(
                        onTap: _toggleFavorite,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: isFavorite
                                ? Colors.yellow.shade100
                                : Colors.grey.shade200,
                            shape: BoxShape.circle,
                            boxShadow: isFavorite
                                ? [
                                    BoxShadow(
                                      color: Colors.yellow.shade400,
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : [],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            isFavorite ? Icons.star : Icons.star_border,
                            color: isFavorite ? Colors.orange : Colors.grey,
                            size: 30,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  description,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Steps:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: steps.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}. ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                steps[index],
                                style: const TextStyle(fontSize: 15.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                if (!isGuest) ...[
                  Column(
                    children: [
                      Text(
                        'Your Rating: ${userRating?.toStringAsFixed(1) ?? "Not Rated"}',
                        style: const TextStyle(fontSize: 15),
                      ),
                      Slider(
                        value: userRating ?? 1.0,
                        onChanged: (value) =>
                            setState(() => userRating = value),
                        onChangeEnd: _updateRating,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: userRating?.toStringAsFixed(1),
                        activeColor: Colors.blueAccent,
                      ),
                    ],
                  ),
                ],
                Center(
                  child: Text(
                    'Average Rating: ${averageRating.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                if (!isGuest)
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _showConfirmationDialog,
                      icon: const Icon(Icons.check),
                      label: const Text('Mark as Completed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
