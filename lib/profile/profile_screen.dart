import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'favorite_workouts/favorite_workouts_screen.dart';
import '../login/login_screen.dart';
import 'settings/settings_screen.dart';
import 'favorite_recipes/favorite_recipes_screen.dart';
import 'profile_header.dart';
import 'profile_menu_button.dart';
import '../../services/profile_image_service.dart';
import 'community/community_screen.dart';
import 'statistics/widgets/weight_chart_card.dart';
import 'statistics/widgets/workout_progress_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  String? _profileImageUrl;
  String? _defaultProfileImageUrl;

  final TextEditingController _weightController = TextEditingController();
  double _rmr = 0.0;
  Map<String, double> _calorieLevels = {};
  Map<String, dynamic>? _userData;
  int _completedWorkouts = 0;

  @override
  void initState() {
    super.initState();
    _loadDefaultProfileImageUrl();
    _fetchUserData();
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
    if (user == null) return;

    final downloadUrl = await ProfileImageService.uploadProfileImage(
      user!,
      currentImageUrl: _profileImageUrl,
    );

    if (downloadUrl != null) {
      setState(() {
        _profileImageUrl = downloadUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error uploading profile image')),
      );
    }
  }

  Future<void> _fetchUserData() async {
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
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

  Future<void> _addWeight() async {
    if (_weightController.text.isNotEmpty && user != null) {
      double weight = double.parse(_weightController.text);
      await FirebaseFirestore.instance
          .collection('weights')
          .doc(user!.uid)
          .collection('entries')
          .add({'weight': weight, 'date': Timestamp.now()});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'weight': weight});

      _weightController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weight added successfully')),
      );
      _fetchUserData();
    }
  }

  Future<void> _deleteLastWeight() async {
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('weights')
          .doc(user!.uid)
          .collection('entries')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Last weight entry deleted')),
        );
        _fetchUserData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = user?.isAnonymous ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!isGuest)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'settings') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                } else if (value == 'logout') {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        TextButton(
                          child: const Text('Logout'),
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'settings',
                  child: Text('Settings'),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Logout'),
                ),
              ],
            )
        ],
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
      body: isGuest
          ? Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_outline,
                      size: 100, color: Colors.blueAccent),
                  const SizedBox(height: 20),
                  const Text(
                    "You are currently using the app as a Guest.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    icon: const Icon(Icons.login, color: Colors.white),
                    label: const Text("Create account here",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
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

                    final userData = snapshot.data!;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ProfileHeader(
                          profileImageUrl: _profileImageUrl,
                          defaultProfileImageUrl: _defaultProfileImageUrl,
                          onImageTap: _uploadProfileImage,
                          username: userData['username'] ?? 'N/A',
                        ),
                        ProfileMenuButton(
                          title: "Favorite Workouts",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const FavoriteWorkoutsScreen(),
                              ),
                            );
                          },
                        ),
                        ProfileMenuButton(
                          title: "Favorite Recipes",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const FavoriteRecipesScreen(),
                              ),
                            );
                          },
                        ),
                        ProfileMenuButton(
                          title: "Community",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CommunityScreen(),
                              ),
                            );
                          },
                        ),

                        // ✅ STATISZTIKÁK IDE KERÜLTEK ÁT
                        const SizedBox(height: 30),
                        WorkoutProgressCard(
                            completedWorkouts: _completedWorkouts),
                        const SizedBox(height: 20),
                        const WeightChartCard(),
                        const SizedBox(height: 20),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Update Weight',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: _weightController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter weight in kg',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: _addWeight,
                                            icon: const Icon(Icons.add),
                                            label: const Text("Add Weight"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.blueAccent,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: _deleteLastWeight,
                                            icon: const Icon(
                                                Icons.delete_outline),
                                            label: const Text("Delete Last"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        const SizedBox(height: 28),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Calorie Levels',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _calorieLevels.entries.map((entry) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      child: Text(
                                        '${entry.key}: ${entry.value.toStringAsFixed(0)} kcal',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    );
                  },
                ),
              ),
            ),
    );
  }
}
