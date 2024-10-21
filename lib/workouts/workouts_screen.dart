import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Kép kiválasztásához
import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage
import 'dart:io'; // Fájl kezelése
import 'category_workouts_screen.dart'; // Az általános edzések listázó képernyő importálása
import 'package:firebase_auth/firebase_auth.dart'; // Felhasználó ellenőrzéséhez

class WorkoutsScreen extends StatefulWidget {
  WorkoutsScreen({super.key});

  @override
  _WorkoutsScreenState createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  String? userRole;

  @override
  void initState() {
    super.initState();
    _getCurrentUserRole();
  }

  // Felhasználó szerepkörének lekérdezése Firestore-ból
  Future<void> _getCurrentUserRole() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      setState(() {
        userRole = userDoc['role'];
      });
    }
  }

  // Új kategória hozzáadása a Firestore-hoz
  Future<void> addCategory(BuildContext context) async {
    if (userRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admins can add categories')),
      );
      return;
    }

    TextEditingController titleController = TextEditingController();
    XFile? pickedImage;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Category Title',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final picker = ImagePicker();
                pickedImage =
                    await picker.pickImage(source: ImageSource.gallery);
                if (pickedImage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Image selected')),
                  );
                }
              },
              child: const Text('Select Image'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && pickedImage != null) {
                final storageRef = FirebaseStorage.instance
                    .ref()
                    .child('category_images/categoryImages')
                    .child('${titleController.text}.jpg');

                await storageRef.putFile(File(pickedImage!.path));
                final imageUrl = await storageRef.getDownloadURL();

                await FirebaseFirestore.instance.collection('categories').add({
                  'title': titleController.text,
                  'image': imageUrl,
                });

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Category added successfully')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Please enter a title and select an image')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Kategória módosítása és törlése
  Future<void> editCategory(BuildContext context, String docId,
      String currentTitle, String currentImage) async {
    if (userRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admins can edit categories')),
      );
      return;
    }

    TextEditingController titleController =
        TextEditingController(text: currentTitle);
    XFile? pickedImage;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Category Title',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final picker = ImagePicker();
                pickedImage =
                    await picker.pickImage(source: ImageSource.gallery);
                if (pickedImage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Image selected')),
                  );
                }
              },
              child: const Text('Select New Image'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                String imageUrl = currentImage;
                if (pickedImage != null) {
                  final storageRef = FirebaseStorage.instance
                      .ref()
                      .child('category_images/categoryImages')
                      .child('${titleController.text}.jpg');

                  await storageRef.putFile(File(pickedImage!.path));
                  imageUrl = await storageRef.getDownloadURL();
                }

                await FirebaseFirestore.instance
                    .collection('categories')
                    .doc(docId)
                    .update({
                  'title': titleController.text,
                  'image': imageUrl,
                });

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Category updated successfully')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a title')),
                );
              }
            },
            child: const Text('Update'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('categories')
                  .doc(docId)
                  .delete();

              if (currentImage.isNotEmpty) {
                try {
                  final storageRef =
                      FirebaseStorage.instance.refFromURL(currentImage);
                  await storageRef.delete();
                } catch (e) {
                  print('Error deleting image from Storage: $e');
                }
              }

              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Category deleted successfully')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Categories'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categories').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading categories'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No categories found'));
          }

          List<QueryDocumentSnapshot> categories = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 1.0,
              ),
              itemCount: categories.length,
              itemBuilder: (BuildContext context, int index) {
                String categoryTitle = categories[index]['title'] ?? 'No title';
                String categoryImage = categories[index]['image'] ?? '';
                String docId = categories[index].id;

                return Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryWorkoutsScreen(
                              category: categoryTitle,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: categoryImage.isNotEmpty
                                ? NetworkImage(categoryImage)
                                : NetworkImage(
                                    'https://firebasestorage.googleapis.com/v0/b/fitwithus-c4ae9.appspot.com/o/category_images%2FplaceholderImage%2Fplaceholder.jpg?alt=media&token=bd57247b-4a73-ac18-3d5d93b15960'),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            color: Colors.black54,
                            child: Text(
                              categoryTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (userRole == 'admin')
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => editCategory(
                              context, docId, categoryTitle, categoryImage),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(6.0),
                            child: const Icon(
                              Icons.settings,
                              color: Colors.white,
                              size: 24.0,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: userRole == 'admin'
          ? FloatingActionButton(
              onPressed: () => addCategory(context),
              child: const Icon(Icons.add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
