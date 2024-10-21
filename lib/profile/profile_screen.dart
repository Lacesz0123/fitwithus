import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore importálása
import 'package:image_picker/image_picker.dart'; // Image picker importálása
import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage importálása
import 'dart:io'; // Fájlkezelés
import '../main.dart'; // Importáljuk a login_screen fájlt, hogy oda irányítsuk vissza a felhasználót
import 'favorite_workouts_screen.dart'; // Importáljuk a kedvenc edzések képernyőt

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  String? _profileImageUrl; // Profilkép URL tárolása
  String? _defaultProfileImageUrl; // Default profilkép URL

  @override
  void initState() {
    super.initState();
    _loadDefaultProfileImageUrl(); // Default kép URL betöltése a Firebase Storage-ból
  }

  // Default profilkép URL lekérdezése Firebase Storage-ból
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

  // Firestore-ból adat lekérő függvény
  Future<Map<String, dynamic>?> getUserData() async {
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      _profileImageUrl = data?['profileImageUrl']; // Profilkép URL lekérése
      return data;
    }
    return null;
  }

  // Profilkép feltöltése Firebase Storage-ba a profile_images/userImages/ mappába
  Future<void> _uploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        // Előző kép törlése a Storage-ból, ha van
        if (_profileImageUrl != null) {
          try {
            final oldImageRef =
                FirebaseStorage.instance.refFromURL(_profileImageUrl!);
            await oldImageRef.delete();
          } catch (e) {
            print('Error deleting previous profile image: $e');
          }
        }

        // Új kép feltöltése Firebase Storage-ba a profile_images/userImages mappába
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images/userImages')
            .child('${user!.uid}.jpg');

        await storageRef.putFile(File(pickedFile.path));
        final downloadUrl = await storageRef.getDownloadURL();

        // Profilkép URL elmentése a Firestore 'users' dokumentumba
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({'profileImageUrl': downloadUrl});

        setState(() {
          _profileImageUrl =
              downloadUrl; // Kép frissítése a felhasználói felületen
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
    // Megerősítés kérdése a felhasználótól
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
        // Profilkép törlése a Storage-ból, ha van
        if (_profileImageUrl != null) {
          try {
            final imageRef =
                FirebaseStorage.instance.refFromURL(_profileImageUrl!);
            await imageRef.delete();
          } catch (e) {
            print('Error deleting profile image from Storage: $e');
          }
        }

        // Törlés a Firestore 'users' gyűjteményéből
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .delete();

        // Felhasználó törlése a Firebase Authentication-ből
        await user!.delete();

        // Kijelentkezés és átirányítás a bejelentkezési oldalra
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
            String email = user?.email ?? 'N/A';
            int weight = userData['weight'] ?? 0;
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
                  "Email: $email",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  "Weight: $weight kg",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
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
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text("Log Out"),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _deleteAccount,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Delete Account"),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
