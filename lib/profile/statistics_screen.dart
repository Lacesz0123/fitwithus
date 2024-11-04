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
  String? _selectedActivityLevel;
  double _rmr = 0.0;
  double _maintenanceCalories = 0.0;
  Map<String, dynamic>? _userData;

  // Súly hozzáadása Firestore-hoz
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

      // Súly frissítése a users collection-ben
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'weight': weight});

      _weightController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weight added successfully')),
      );
      _fetchUserData(); // Frissítjük az adatokat és a kalóriaszámítást
    }
  }

  // Felhasználói adatok lekérése a kalóriaszámításhoz
  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _userData = userDoc.data() as Map<String, dynamic>?;
        _rmr = 0.0;
        _maintenanceCalories = 0.0;
      });
    }
  }

  // Kalóriák kiszámítása
  void _calculateCalories() {
    if (_userData != null &&
        _userData!['weight'] != null &&
        _userData!['height'] != null &&
        _userData!['birthDate'] != null &&
        _userData!['gender'] != null) {
      double weight = (_userData!['weight'] as num).toDouble();
      double height = (_userData!['height'] as num).toDouble();

      // Ellenőrzés és konverzió DateTime típusra
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

      if (_selectedActivityLevel != null) {
        switch (_selectedActivityLevel) {
          case 'No Activity':
            _maintenanceCalories = _rmr * 1.2;
            break;
          case 'Light Activity':
            _maintenanceCalories = _rmr * 1.375;
            break;
          case 'Moderate Activity':
            _maintenanceCalories = _rmr * 1.55;
            break;
          case 'High Activity':
            _maintenanceCalories = _rmr * 1.725;
            break;
          case 'Very High Activity':
            _maintenanceCalories = _rmr * 1.9;
            break;
        }
      }
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
      appBar: AppBar(title: const Text('Statistics')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Weight Change Over Time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getWeightEntries(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No weight data available');
                  }

                  List<Map<String, dynamic>> weightEntries = snapshot.data!;
                  return SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        lineBarsData: [
                          LineChartBarData(
                            spots: weightEntries.map((entry) {
                              DateTime date =
                                  (entry['date'] as Timestamp).toDate();
                              return FlSpot(
                                  date.millisecondsSinceEpoch.toDouble(),
                                  (entry['weight'] as num).toDouble());
                            }).toList(),
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 2,
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 604800000, // 1 week in milliseconds
                              getTitlesWidget: (value, meta) {
                                DateTime date =
                                    DateTime.fromMillisecondsSinceEpoch(
                                        value.toInt());
                                return Text('${date.month}/${date.day}');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter Weight (kg)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addWeight,
                child: const Text('Add Weight'),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              const Text(
                'Calorie Calculator',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Select Activity Level',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: _selectedActivityLevel,
                hint: const Text('Select Activity Level'),
                items: [
                  'No Activity',
                  'Light Activity',
                  'Moderate Activity',
                  'High Activity',
                  'Very High Activity'
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedActivityLevel = newValue;
                    _calculateCalories();
                  });
                },
              ),
              const SizedBox(height: 20),
              if (_rmr > 0 && _maintenanceCalories > 0)
                Column(
                  children: [
                    Text(
                      'RMR (Resting Metabolic Rate): ${_rmr.toStringAsFixed(2)} kcal',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Maintenance Calories: ${_maintenanceCalories.toStringAsFixed(2)} kcal',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Súlyadatok lekérése diagram megjelenítéséhez
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
