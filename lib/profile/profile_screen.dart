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
import 'weight_chart_card.dart';
import 'workout_progress_card.dart';
import 'user_management/user_management_screen.dart';

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
  int _dailyCalories = 0;
  final TextEditingController _calorieInputController = TextEditingController();

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
      if (data != null) {
        _profileImageUrl = data['profileImageUrl'];
      }
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
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>?;
          _dailyCalories = _userData?['dailyCalories'] ?? 0;
          _completedWorkouts = _userData?['completedWorkouts'] ?? 0;
          _calculateCalories();
        });
      } else {
        // Ha valamiért a dokumentum nem létezik, jelezzük
        print('User document does not exist in Firestore.');
      }
    }
  }

  void _calculateCalories() {
    if (_userData != null &&
        _userData!.containsKey('weight') &&
        _userData!.containsKey('height') &&
        _userData!.containsKey('birthDate') &&
        _userData!.containsKey('gender')) {
      double weight = (_userData!['weight'] as num?)?.toDouble() ?? 70.0;
      double height = (_userData!['height'] as num?)?.toDouble() ?? 170.0;

      DateTime birthDate;
      if (_userData!['birthDate'] is Timestamp) {
        birthDate = (_userData!['birthDate'] as Timestamp).toDate();
      } else if (_userData!['birthDate'] is String) {
        birthDate = DateTime.parse(_userData!['birthDate']);
      } else {
        birthDate = DateTime(1990, 1, 1); // Fallback születési idő
      }

      int age = DateTime.now().year - birthDate.year;
      if (DateTime.now().month < birthDate.month ||
          (DateTime.now().month == birthDate.month &&
              DateTime.now().day < birthDate.day)) {
        age--;
      }

      String gender = _userData!['gender'] ?? 'Male';
      if (gender == 'Male') {
        _rmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
      } else if (gender == 'Female') {
        _rmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
      } else {
        _rmr = (10 * weight) + (6.25 * height) - (5 * age) - 161; // Fallback
      }

      _calorieLevels = {
        'No Activity': _rmr * 1.2,
        'Light Activity': _rmr * 1.375,
        'Moderate Activity': _rmr * 1.55,
        'High Activity': _rmr * 1.725,
        'Very High Activity': _rmr * 1.9,
      };
    } else {
      // Fallback értékek, ha az adatok hiányoznak
      _calorieLevels = {
        'No Activity': 0.0,
        'Light Activity': 0.0,
        'Moderate Activity': 0.0,
        'High Activity': 0.0,
        'Very High Activity': 0.0,
      };
    }
  }

  Future<void> _addWeight() async {
    if (_weightController.text.isNotEmpty && user != null) {
      final input = double.tryParse(_weightController.text);
      if (input == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid number format')),
        );
        return;
      }

      if (input < 0 || input > 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weight must be between 0 and 200 kg')),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('weights')
          .doc(user!.uid)
          .collection('entries')
          .add({'weight': input, 'date': Timestamp.now()});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'weight': input});

      _weightController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weight added successfully')),
      );
      _fetchUserData();
    }
  }

  Future<void> _addCalories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _calorieInputController.text.isNotEmpty) {
      int added = int.tryParse(_calorieInputController.text) ?? 0;
      if (added > 0) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {'dailyCalories': _dailyCalories + added},
          SetOptions(merge: true),
        );
        setState(() {
          _dailyCalories += added;
        });
        _calorieInputController.clear();
      }
    }
  }

  Future<void> _resetCalories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'dailyCalories': 0},
        SetOptions(merge: true),
      );
      setState(() {
        _dailyCalories = 0;
      });
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'settings',
                  child: Text('Settings'),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Text('Logout'),
                ),
              ],
            ),
        ],
        flexibleSpace: Theme.of(context).brightness == Brightness.dark
            ? Container(
                color: const Color(0xFF1E1E1E),
              )
            : Container(
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
                  Icon(
                    Icons.person_outline,
                    size: 100,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.blueAccent,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "You are currently using the app as a Guest.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
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
                    icon: Icon(
                      Icons.login,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.white,
                    ),
                    label: Text(
                      "Create account here",
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade800
                              : Colors.blueAccent,
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
              physics: const BouncingScrollPhysics(),
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
                      // Ha valamiért nincs adat, próbáljuk újra betölteni
                      _fetchUserData();
                      return const CircularProgressIndicator();
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
                        if (_userData?['role'] == 'admin')
                          ProfileMenuButton(
                            title: "User Management",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const UserManagementScreen(),
                                ),
                              );
                            },
                          ),
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
                              Text(
                                'Update Weight',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.color,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                  ),
                                  boxShadow: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? []
                                      : [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.03),
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
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color),
                                      decoration: InputDecoration(
                                        hintText: 'Enter weight in kg',
                                        hintStyle: TextStyle(
                                          color: Theme.of(context).hintColor,
                                        ),
                                        border: OutlineInputBorder(),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 10),
                                        filled: true,
                                        fillColor: Theme.of(context).cardColor,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: _addWeight,
                                            icon: const Icon(Icons.add,
                                                color: Colors.white),
                                            label: const Text("Add Weight"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey.shade700
                                                  : Colors.blueAccent,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: _deleteLastWeight,
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.white),
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
                        const SizedBox(height: 28),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily Calorie Intake',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.color,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                  ),
                                  boxShadow: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? []
                                      : [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.03),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current: ${_dailyCalories.toStringAsFixed(0)} kcal',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ..._calorieLevels.entries.map((entry) {
                                      final label = entry.key;
                                      final goal = entry.value;
                                      final current = _dailyCalories;
                                      final progress =
                                          (current / goal).clamp(0.0, 1.0);

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$label: ${current > goal ? goal.toStringAsFixed(0) : current.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} kcal',
                                              style:
                                                  const TextStyle(fontSize: 15),
                                            ),
                                            const SizedBox(height: 4),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: LinearProgressIndicator(
                                                value: progress,
                                                minHeight: 14,
                                                backgroundColor:
                                                    Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.grey.shade700
                                                        : Colors.grey.shade300,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.blueAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _calorieInputController,
                                            keyboardType: TextInputType.number,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Enter kcal (e.g. 200)',
                                              hintStyle: TextStyle(
                                                color:
                                                    Theme.of(context).hintColor,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 10),
                                              filled: true,
                                              fillColor:
                                                  Theme.of(context).cardColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: _addCalories,
                                          icon: const Icon(Icons.add,
                                              color: Colors.white),
                                          label: const Text("Add"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.grey.shade700
                                                    : Colors.blueAccent,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 28, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                title: const Text(
                                                    "Reset Calories"),
                                                content: const Text(
                                                    "Are you sure you want to reset your daily calories?"),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(),
                                                    child: const Text("Cancel"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                      _resetCalories();
                                                    },
                                                    child: const Text("Reset"),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.refresh,
                                              color: Colors.white),
                                          label: const Text("Reset"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 28, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
