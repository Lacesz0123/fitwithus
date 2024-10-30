import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitwithus/main.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'favorite_workouts_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'favorite_recipes_screen.dart'; // Importáljuk a kedvenc receptek képernyőt

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

  Widget _buildMenuButton(String title, VoidCallback onPressed,
      {Color? color, Color textColor = Colors.black}) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: color, // Beállítjuk a háttérszínt, ha meg van adva
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              foregroundColor: textColor,
              backgroundColor: Colors.transparent, // Átlátszó háttér a gombon
            ),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const Divider(
          color: Colors.black,
          thickness: 0.5,
          height: 0,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
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
                  _buildMenuButton("Favorite Workouts", () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const FavoriteWorkoutsScreen(),
                      ),
                    );
                  }),
                  _buildMenuButton("Favorite Recipes", () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const FavoriteRecipesScreen(),
                      ),
                    );
                  }),
                  _buildMenuButton("Statistics", () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const StatisticsScreen(),
                      ),
                    );
                  }),
                  _buildMenuButton("Settings", () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  }),
                  _buildMenuButton("Logout", () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  }),
                  _buildMenuButton(
                    "Delete Account",
                    _deleteAccount,
                    color: Colors.red, // Piros háttér teljes szélességben
                    textColor: Colors.white,
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
