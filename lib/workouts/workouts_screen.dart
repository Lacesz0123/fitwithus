import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Kép kiválasztásához
import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage
import 'dart:io'; // Fájl kezelése
import 'category_workouts_screen.dart'; // Az általános edzések listázó képernyő importálása

class WorkoutsScreen extends StatelessWidget {
  WorkoutsScreen({super.key});

  // Kategóriák lekérdezése a Firestore-ból
  Future<List<Map<String, dynamic>>> getCategories() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('categories').get();

    return querySnapshot.docs.map((doc) {
      // A dokumentum adataihoz hozzáadjuk az azonosítót is
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Az azonosítót a data-hoz adjuk
      return data;
    }).toList();
  }

  // Új kategória hozzáadása a Firestore-hoz
  Future<void> addCategory(BuildContext context) async {
    TextEditingController titleController = TextEditingController();
    XFile? pickedImage;

    // Kategória hozzáadásának párbeszédablaka
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
              if (titleController.text.isNotEmpty) {
                // Ha nincs kép kiválasztva, használjuk a placeholder képet
                String imageUrl;
                if (pickedImage == null) {
                  imageUrl =
                      'https://firebasestorage.googleapis.com/v0/b/fitwithus-c4ae9.appspot.com/o/category_images%2FplaceholderImage%2Fplaceholder.jpg?alt=media';
                } else {
                  // Kép feltöltése a "category_images/categoryImages" mappába
                  final storageRef = FirebaseStorage.instance
                      .ref()
                      .child('category_images/categoryImages')
                      .child('${titleController.text}.jpg');

                  await storageRef.putFile(File(pickedImage!.path));
                  imageUrl = await storageRef.getDownloadURL();
                }

                // Új kategória mentése Firestore-ba
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
                  const SnackBar(content: Text('Please enter a title')),
                );
              }
            },
            child: const Text('Add'),
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading categories'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No categories found'));
          }

          List<Map<String, dynamic>> categories = snapshot.data!;

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
                String docId = categories[index]['id']; // Dokumentum azonosító

                return GestureDetector(
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
                                'https://firebasestorage.googleapis.com/v0/b/fitwithus-c4ae9.appspot.com/o/category_images%2FplaceholderImage%2Fplaceholder.jpg?alt=media'),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Stack(
                      children: [
                        Align(
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
                        Positioned(
                          top: 8.0,
                          right: 8.0,
                          child: IconButton(
                            icon:
                                const Icon(Icons.settings, color: Colors.white),
                            onPressed: () {
                              // Itt fog történni a módosítási funkció
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addCategory(context),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
