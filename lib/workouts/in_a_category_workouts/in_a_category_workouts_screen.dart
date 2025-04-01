import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'widgets/edit_workout_category_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/workout_category_card.dart';
import 'widgets/add_workout_category_dialog.dart';
import 'widgets/workout_category_search_delegate.dart';

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

    showDialog(
      context: context,
      builder: (context) => const AddCategoryDialog(),
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

    showDialog(
      context: context,
      builder: (context) => EditCategoryDialog(
        docId: docId,
        currentTitle: currentTitle,
        currentImage: currentImage,
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

                      return WorkoutCategoryCard(
                        title: categoryTitle,
                        imageUrl: categoryImage,
                        docId: docId,
                        userRole: userRole,
                        onEditTap: () => editCategory(
                            context, docId, categoryTitle, categoryImage),
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
