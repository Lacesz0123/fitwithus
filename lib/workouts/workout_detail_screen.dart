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

  @override
  void initState() {
    super.initState();
    _checkIfFavorite(); // Ellenőrizzük, hogy kedvenc-e az edzés
  }

  Future<Map<String, dynamic>?> getWorkoutData() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('workouts')
        .doc(widget.workoutId)
        .get();
    return doc.data() as Map<String, dynamic>?;
  }

  // Ellenőrizzük, hogy az edzés már kedvenc-e a Firestore-ban
  Future<void> _checkIfFavorite() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      // Ellenőrizzük, hogy létezik-e a 'favorites' mező, ha nem, akkor üres listát adunk
      List<dynamic> favoriteWorkouts =
          (doc.data() as Map<String, dynamic>)['favorites'] ?? [];

      setState(() {
        isFavorite = favoriteWorkouts.contains(widget.workoutId);
      });
    }
  }

  // Kedvencekhez adás vagy eltávolítás
  Future<void> _toggleFavorite() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      DocumentSnapshot doc = await userRef.get();
      List<dynamic> favoriteWorkouts = doc['favorites'] ?? [];

      if (favoriteWorkouts.contains(widget.workoutId)) {
        // Eltávolítjuk a kedvencek közül
        await userRef.update({
          'favorites': FieldValue.arrayRemove([widget.workoutId])
        });
        setState(() {
          isFavorite = false;
        });
      } else {
        // Hozzáadjuk a kedvencekhez
        await userRef.update({
          'favorites': FieldValue.arrayUnion([widget.workoutId])
        });
        setState(() {
          isFavorite = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Details'),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Colors.yellow : Colors.grey,
            ),
            onPressed: _toggleFavorite, // Kedvenc állapot váltása
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getWorkoutData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading workout details'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Workout not found'));
          }

          // Lekért adatok
          Map<String, dynamic> workoutData = snapshot.data!;
          String title = workoutData['title'] ?? 'No title';
          String description = workoutData['description'] ?? 'No description';
          List<dynamic> steps = workoutData['steps'] ?? [];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Steps:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ...steps.map((step) => Text(
                      '- $step',
                      style: const TextStyle(fontSize: 18),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}
