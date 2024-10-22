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
              maxLength: 18, // Maximális karakterhossz beállítása
              decoration: const InputDecoration(
                hintText: 'Category Title',
                counterText: '', // Karakter számláló elrejtése
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
              if (titleController.text.isNotEmpty &&
                  titleController.text.length <=
                      18 && // Karakterhossz ellenőrzés
                  pickedImage != null) {
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
                      content: Text(
                          'Please enter a title (max 18 characters) and select an image')),
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
              maxLength: 18, // Maximális karakterhossz beállítása
              decoration: const InputDecoration(
                hintText: 'Category Title',
                counterText: '', // Karakter számláló elrejtése
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
              if (titleController.text.isNotEmpty &&
                  titleController.text.length <= 18) {
                // Karakterhossz ellenőrzés
                String imageUrl = currentImage;
                // Ha új kép van kiválasztva, töröljük a régit
                if (pickedImage != null) {
                  try {
                    final oldImageRef =
                        FirebaseStorage.instance.refFromURL(currentImage);
                    await oldImageRef.delete();
                  } catch (e) {
                    print('Error deleting previous image from Storage: $e');
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
                      content:
                          Text('Please enter a title (max 18 characters)')),
                );
              }
            },
            child: const Text('Update'),
          ),
          TextButton(
            onPressed: () async {
              // Kategória és kapcsolódó gyakorlatok törlése
              try {
                // Először töröljük a kategóriához tartozó összes gyakorlatot
                QuerySnapshot workoutsSnapshot = await FirebaseFirestore
                    .instance
                    .collection('workouts')
                    .where('category', isEqualTo: currentTitle)
                    .get();

                for (DocumentSnapshot workoutDoc in workoutsSnapshot.docs) {
                  await FirebaseFirestore.instance
                      .collection('workouts')
                      .doc(workoutDoc.id)
                      .delete();
                }

                // Ezután töröljük a kategóriát
                await FirebaseFirestore.instance
                    .collection('categories')
                    .doc(docId)
                    .delete();

                // Ha van kép a kategóriához, töröljük azt is
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
                      content:
                          Text('Category and workouts deleted successfully')),
                );
              } catch (e) {
                print('Error deleting category and workouts: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Error deleting category and workouts')),
                );
              }
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
        actions: [
          // Keresés ikon hozzáadása
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
          ? FloatingActionButton.extended(
              onPressed: () => addCategory(context),
              label: Row(
                children: const [
                  Text('Add New'), // A szöveg
                  SizedBox(width: 5), // Kis távolság a szöveg és az ikon között
                  Icon(Icons.add), // Az ikon a szöveg után
                ],
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// Keresési funkció implementációja
class CategorySearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = ''; // Keresési lekérdezés törlése
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null); // Keresés bezárása
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: query + '\uf8ff')
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
                  ? Image.network(categoryImage, width: 50, height: 50)
                  : const Icon(Icons.category),
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
