import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

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
      // Kérjük le a legutolsó bejegyzést
      final snapshot = await FirebaseFirestore.instance
          .collection('weights')
          .doc(user.uid)
          .collection('entries')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        try {
          // Töröljük a legutolsó bejegyzést
          await snapshot.docs.first.reference.delete();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Last weight entry deleted successfully')),
          );

          _fetchUserData(); // Frissítsük az adatokat
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

  Widget _buildProgressBar(String label, int completed, int goal, Color color) {
    double progress = completed / goal;
    progress =
        progress > 1.0 ? 1.0 : progress; // Limitáljuk a maximumot 100%-ra

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        Stack(
          children: [
            Container(
              width: double.infinity,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.9 * progress,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          '${(progress * 100).toStringAsFixed(1)}% (${completed}/$goal)',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
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
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Workout Progress Goals',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildProgressBar('10 Workouts Goal',
                            _completedWorkouts, 10, Colors.green),
                        const SizedBox(height: 10),
                        _buildProgressBar('50 Workouts Goal',
                            _completedWorkouts, 50, Colors.orange),
                        const SizedBox(height: 10),
                        _buildProgressBar('100 Workouts Goal',
                            _completedWorkouts, 100, Colors.red),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
                          'Weight Change Over Time',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _getWeightEntries(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Text('No weight data available');
                            }

                            List<Map<String, dynamic>> weightEntries =
                                snapshot.data!;
                            return SizedBox(
                              height: 200,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawHorizontalLine: true,
                                    drawVerticalLine: false,
                                    horizontalInterval:
                                        50, // Csak a bal oldali értékekhez
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: Colors.grey.withOpacity(
                                            0.2), // Lágy szürke vonalak
                                        strokeWidth: 1,
                                      );
                                    },
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: const Border(
                                      left: BorderSide(color: Colors.grey),
                                      bottom: BorderSide(
                                          color: Colors
                                              .transparent), // Alsó vonal eltávolítása
                                      right:
                                          BorderSide(color: Colors.transparent),
                                      top:
                                          BorderSide(color: Colors.transparent),
                                    ),
                                  ),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: weightEntries.map((entry) {
                                        DateTime date =
                                            (entry['date'] as Timestamp)
                                                .toDate();
                                        return FlSpot(
                                          date.millisecondsSinceEpoch
                                              .toDouble(),
                                          (entry['weight'] as num).toDouble(),
                                        );
                                      }).toList(),
                                      isCurved: true,
                                      color: Colors.teal,
                                      barWidth: 4,
                                      dotData: FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Colors.teal.withOpacity(0.1),
                                      ),
                                    ),
                                  ],
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                          showTitles:
                                              false), // Dátumok eltávolítása
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        interval: 50, // 50 kg lépésköz
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            '${value.toInt()} kg',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                          showTitles:
                                              false), // Jobb oldali tengely eltávolítása
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                          showTitles:
                                              false), // Felső tengely eltávolítása
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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

  Stream<List<Map<String, dynamic>>> _getWeightEntries() {
    final user = FirebaseAuth.instance.currentUser;
    return FirebaseFirestore.instance
        .collection('weights')
        .doc(user?.uid)
        .collection('entries')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList());
  }
}
