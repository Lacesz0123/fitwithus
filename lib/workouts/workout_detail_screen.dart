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
            return const Center(child: Text('Hiba az edzés betöltése közben'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Nincs ilyen edzés'));
          }

          // Lekért adatok
          Map<String, dynamic> workoutData = snapshot.data!;
          String title = workoutData['title'] ?? 'Cím nélkül';
          String description = workoutData['description'] ?? 'Nincs leírás';
          List<dynamic> steps = workoutData['steps'] ?? [];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _toggleFavorite,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: isFavorite
                              ? Colors.yellow.shade100
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (isFavorite)
                              BoxShadow(
                                color: Colors.yellow.shade400,
                                blurRadius: 10,
                                spreadRadius: 1,
                              )
                          ],
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
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(fontSize: 18, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Lépések:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 10),
                // Lépések kártya-stílusú megjelenítése
                Expanded(
                  child: ListView.builder(
                    itemCount: steps.length,
                    itemBuilder: (context, index) {
                      String step = steps[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${index + 1}. ',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  step,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
