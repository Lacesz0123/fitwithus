import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import '../main.dart';
import 'favorite_workouts_screen.dart';
import 'settings_screen.dart'; // Új SettingsScreen importálása

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  String? _profileImageUrl;
  String? _defaultProfileImageUrl;
  TextEditingController _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDefaultProfileImageUrl();
  }

  Future<void> _loadDefaultProfileImageUrl() async {
    try {
      final defaultRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/defaultImage/default.jpg');
      final url = await defaultRef.getDownloadURL();
      setState(() {
        _defaultProfileImageUrl = url;
      });
    } catch (e) {
      print('Error loading default profile image URL: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      _profileImageUrl = data?['profileImageUrl'];
      return data;
    }
    return null;
  }

  Future<void> _uploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        if (_profileImageUrl != null) {
          try {
            final oldImageRef =
                FirebaseStorage.instance.refFromURL(_profileImageUrl!);
            await oldImageRef.delete();
          } catch (e) {
            print('Error deleting previous profile image: $e');
          }
        }

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images/userImages')
            .child('${user!.uid}.jpg');

        await storageRef.putFile(File(pickedFile.path));
        final downloadUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({'profileImageUrl': downloadUrl});

        setState(() {
          _profileImageUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully')),
        );
      } catch (e) {
        print('Error uploading profile image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error uploading profile image')),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete) {
      try {
        if (_profileImageUrl != null) {
          try {
            final imageRef =
                FirebaseStorage.instance.refFromURL(_profileImageUrl!);
            await imageRef.delete();
          } catch (e) {
            print('Error deleting profile image from Storage: $e');
          }
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .delete();

        await user!.delete();

        await FirebaseAuth.instance.signOut();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Your account has been successfully deleted.')),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Please log in again to confirm account deletion.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.message}')),
          );
        }
      }
    }
  }

  Future<void> _addWeight() async {
    if (_weightController.text.isNotEmpty) {
      double weight = double.parse(_weightController.text);
      await FirebaseFirestore.instance
          .collection('weights')
          .doc(user!.uid)
          .collection('entries')
          .add({
        'weight': weight,
        'date': Timestamp.now(),
      });
      _weightController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weight added successfully')),
      );
    }
  }

  Stream<List<Map<String, dynamic>>> _getWeightEntries() {
    return FirebaseFirestore.instance
        .collection('weights')
        .doc(user!.uid)
        .collection('entries')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Logout') {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              } else if (value == 'Delete Account') {
                _deleteAccount();
              } else if (value == 'Settings') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'Settings',
                child: Text('Settings'),
              ),
              const PopupMenuItem(
                value: 'Logout',
                child: Text('Logout'),
              ),
              const PopupMenuItem(
                value: 'Delete Account',
                child: Text('Delete Account'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: FutureBuilder<Map<String, dynamic>?>(
            future: getUserData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return const Text('Error loading user data');
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return const Text('No user data found');
              }

              Map<String, dynamic> userData = snapshot.data!;
              int completedWorkouts = userData['completedWorkouts'] ?? 0;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _uploadProfileImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : (_defaultProfileImageUrl != null
                              ? NetworkImage(_defaultProfileImageUrl!)
                              : null),
                      backgroundColor: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userData['username'] ?? 'N/A',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Completed Workouts: $completedWorkouts",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const FavoriteWorkoutsScreen(),
                        ),
                      );
                    },
                    child: const Text("Favorite Workouts"),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Weight Change Over Time',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
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
                  SizedBox(
                    width: MediaQuery.of(context).size.width *
                        0.8, // Keskenyebb mező
                    child: TextField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Enter Weight (kg)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _addWeight,
                    child: const Text('Add Weight'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
