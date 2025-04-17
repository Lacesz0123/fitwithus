import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'favorite_workouts/favorite_workouts_screen.dart';
import '../login/login_screen.dart';
import 'settings/settings_screen.dart';
import 'statistics/statistics_screen.dart';
import 'favorite_recipes/favorite_recipes_screen.dart';
import 'profile_header.dart';
import 'profile_menu_button.dart';
import '../../services/profile_image_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  String? _profileImageUrl;
  String? _defaultProfileImageUrl;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Profile'),
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
                          builder: (context) => const FavoriteWorkoutsScreen(),
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
                          builder: (context) => const FavoriteRecipesScreen(),
                        ),
                      );
                    },
                  ),
                  ProfileMenuButton(
                    title: "Statistics",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StatisticsScreen(),
                        ),
                      );
                    },
                  ),
                  ProfileMenuButton(
                    title: "Settings",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  ProfileMenuButton(
                    title: "Logout",
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
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
