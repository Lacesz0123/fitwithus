import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitwithus/profile/statistics/widgets/weight_chart_card.dart';
import 'package:fitwithus/profile/statistics/widgets/workout_progress_card.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final TextEditingController _weightController = TextEditingController();
  double _rmr = 0.0;
  Map<String, double> _calorieLevels = {};
  Map<String, dynamic>? _userData;
  int _completedWorkouts = 0;

  Future<void> _addWeight() async {
    final user = FirebaseAuth.instance.currentUser;
    if (_weightController.text.isNotEmpty && user != null) {
      double weight = double.parse(_weightController.text);
      await FirebaseFirestore.instance
          .collection('weights')
          .doc(user.uid)
          .collection('entries')
          .add({
        'weight': weight,
        'date': Timestamp.now(),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'weight': weight});

      _weightController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weight added successfully')),
      );
      _fetchUserData();
    }
  }

  Future<void> _deleteLastWeight() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('weights')
          .doc(user.uid)
          .collection('entries')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        try {
          await snapshot.docs.first.reference.delete();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Last weight entry deleted successfully')),
          );
          _fetchUserData();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error deleting weight entry')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No weight entries to delete')),
        );
      }
    }
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _userData = userDoc.data() as Map<String, dynamic>?;
        _completedWorkouts = _userData?['completedWorkouts'] ?? 0;
        _calculateCalories();
      });
    }
  }

  void _calculateCalories() {
    if (_userData != null &&
        _userData!['weight'] != null &&
        _userData!['height'] != null &&
        _userData!['birthDate'] != null &&
        _userData!['gender'] != null) {
      double weight = (_userData!['weight'] as num).toDouble();
      double height = (_userData!['height'] as num).toDouble();

      DateTime birthDate;
      if (_userData!['birthDate'] is Timestamp) {
        birthDate = (_userData!['birthDate'] as Timestamp).toDate();
      } else {
        birthDate = DateTime.parse(_userData!['birthDate']);
      }

      int age = DateTime.now().year - birthDate.year;
      if (DateTime.now().month < birthDate.month ||
          (DateTime.now().month == birthDate.month &&
              DateTime.now().day < birthDate.day)) {
        age--;
      }

      if (_userData!['gender'] == 'Male') {
        _rmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
      } else if (_userData!['gender'] == 'Female') {
        _rmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
      }

      _calorieLevels = {
        'No Activity': _rmr * 1.2,
        'Light Activity': _rmr * 1.375,
        'Moderate Activity': _rmr * 1.55,
        'High Activity': _rmr * 1.725,
        'Very High Activity': _rmr * 1.9,
      };
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.lightBlueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Total workouts card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Total Workouts Completed: $_completedWorkouts',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                ),

                // ✅ Kiszervezett workout progress card
                WorkoutProgressCard(completedWorkouts: _completedWorkouts),

                const SizedBox(height: 20),

                // ✅ Kiszervezett weight chart card
                const WeightChartCard(),

                const SizedBox(height: 20),

                // Weight input card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Enter Weight (kg)',
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: _addWeight,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Add Weight'),
                            ),
                            ElevatedButton(
                              onPressed: _deleteLastWeight,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Delete Last'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Calorie levels card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Calorie Levels',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        for (var entry in _calorieLevels.entries)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              '${entry.key}: ${entry.value.toStringAsFixed(2)} kcal',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.black87),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
