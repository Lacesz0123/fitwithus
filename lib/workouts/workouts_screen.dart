import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'category_workouts_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        title: Row(
          children: [
            const Icon(Icons.add, color: Colors.teal),
            const SizedBox(width: 10),
            const Text(
              'Add New Category',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              maxLength: 18,
              decoration: InputDecoration(
                labelText: 'Category Title',
                counterText: '',
                labelStyle: const TextStyle(color: Colors.teal),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.teal, width: 2),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
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
              icon: const Icon(Icons.image, color: Colors.white),
              label: const Text('Select Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  titleController.text.length <= 18 &&
                  pickedImage != null) {
                final storageRef = FirebaseStorage.instance
                    .ref()
                    .child('category_images/categoryImages')
                    .child('${titleController.text}.jpg');

                await storageRef.putFile(File(pickedImage!.path));
                final imageUrl = await storageRef.getDownloadURL();

                await FirebaseFirestore.instance.collection('categories').add({
                  'title': titleController.text,
                  'title_lower': titleController.text.toLowerCase(),
                  'image': imageUrl,
                });

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Category added successfully')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enter a title (max 18 characters) and select an image',
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        title: Row(
          children: [
            const Icon(Icons.edit, color: Colors.blueAccent),
            const SizedBox(width: 10),
            const Text(
              'Edit Category',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              maxLength: 18,
              decoration: InputDecoration(
                labelText: 'Category Title',
                counterText: '',
                labelStyle: const TextStyle(color: Colors.blueAccent),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Colors.blueAccent, width: 2),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
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
              icon: const Icon(Icons.image, color: Colors.white),
              label: const Text('Select New Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty &&
                        titleController.text.length <= 18) {
                      String imageUrl = currentImage;
                      if (pickedImage != null) {
                        try {
                          final oldImageRef =
                              FirebaseStorage.instance.refFromURL(currentImage);
                          await oldImageRef.delete();
                        } catch (e) {
                          print(
                              'Error deleting previous image from Storage: $e');
                        }

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
                        'title_lower': titleController.text.toLowerCase(),
                        'image': imageUrl,
                      });

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Category updated successfully')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Please enter a title (max 18 characters)')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Update'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      QuerySnapshot workoutsSnapshot = await FirebaseFirestore
                          .instance
                          .collection('workouts')
                          .where('category', isEqualTo: currentTitle)
                          .get();

                      for (DocumentSnapshot workoutDoc
                          in workoutsSnapshot.docs) {
                        await FirebaseFirestore.instance
                            .collection('workouts')
                            .doc(workoutDoc.id)
                            .delete();
                      }

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
                        const SnackBar(
                            content: Text(
                                'Category and workouts deleted successfully')),
                      );
                    } catch (e) {
                      print('Error deleting category and workouts: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Error deleting category and workouts')),
                      );
                    }
                  },
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.tealAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CategorySearchDelegate(),
              );
            },
          ),
        ],
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

          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (BuildContext context, int index) {
                      String categoryTitle =
                          categories[index]['title'] ?? 'No title';
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
                                borderRadius: BorderRadius.circular(15.0),
                                image: DecorationImage(
                                  image: categoryImage.isNotEmpty
                                      ? NetworkImage(categoryImage)
                                      : NetworkImage(
                                          'https://firebasestorage.googleapis.com/v0/b/fitwithus-c4ae9.appspot.com/o/category_images%2FplaceholderImage%2Fplaceholder.jpg?alt=media&token=bd57247b-4a73-ac18-3d5d93b15960'),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(15.0),
                                      topRight: Radius.circular(15.0),
                                    ),
                                  ),
                                  child: Text(
                                    categoryTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
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
                                onTap: () => editCategory(context, docId,
                                    categoryTitle, categoryImage),
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
                ),
              ),
              if (userRole == 'admin')
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () => addCategory(context),
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text(
                        'Add New Category',
                        style: TextStyle(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class CategorySearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    String lowerCaseQuery = query.toLowerCase();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .where('title_lower', isGreaterThanOrEqualTo: lowerCaseQuery)
          .where('title_lower', isLessThanOrEqualTo: lowerCaseQuery + '\uf8ff')
          .snapshots(),
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

        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            String categoryTitle = categories[index]['title'] ?? 'No title';
            String categoryImage = categories[index]['image'] ?? '';

            return ListTile(
              leading: categoryImage.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(categoryImage,
                          width: 50, height: 50, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.category, size: 40),
              title: Text(categoryTitle),
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
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
