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
      {Color? color, Color textColor = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: color ??
              const Color.fromARGB(
                  255, 68, 138, 255), // Lágy kék árnyalatú gomb
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            foregroundColor: textColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC), // Lágy világos szürke háttér
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

              Map<String, dynamic> userData = snapshot.data!;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                      height: 30), // Térköz az AppBar és a profilkép között
                  GestureDetector(
                    onTap: _uploadProfileImage,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Colors.tealAccent,
                            Colors.blueAccent
                          ], // Színátmenet a kerethez
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(5), // Keret vastagsága
                      child: CircleAvatar(
                        radius: 65, // A kép mérete kisebb a kerethez képest
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : (_defaultProfileImageUrl != null
                                ? NetworkImage(_defaultProfileImageUrl!)
                                : null),
                        backgroundColor: Colors.white,
                        child: _profileImageUrl == null &&
                                _defaultProfileImageUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 70,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Text(
                    userData['username'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 22, // Nagyobb betűméret
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
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
                    color: Colors
                        .redAccent, // Piros háttér, ami illeszkedik a modern kinézethez
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
