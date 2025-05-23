import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'widgets/edit_workout_category_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/workout_category_card.dart';
import 'widgets/add_workout_category_dialog.dart';
import 'widgets/workout_category_search_delegate.dart';
import '../../../utils/custom_snackbar.dart';

/// Az edzéskategóriákat megjelenítő fő képernyő.
///
/// A felhasználó itt böngészhet a létrehozott kategóriák között.
/// Ha admin jogosultsággal rendelkezik, lehetősége van:
/// - Új kategória létrehozására
/// - Kategóriák szerkesztésére
/// - Kategóriák keresésére
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

  /// Lekéri az aktuális felhasználó szerepkörét (pl. `admin`) a Firestore-ból.
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

  /// Új kategória hozzáadása dialógusablakban.
  /// Csak admin szerepkör esetén érhető el.
  Future<void> addCategory(BuildContext context) async {
    if (userRole != 'admin') {
      showCustomSnackBar(context, 'Only admins can add categories',
          isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => const AddCategoryDialog(),
    );
  }

  /// Kategória szerkesztése dialógusablakban az adott dokumentum azonosító és adatok alapján.
  /// Csak admin számára.
  Future<void> editCategory(BuildContext context, String docId,
      String currentTitle, String currentImage) async {
    if (userRole != 'admin') {
      showCustomSnackBar(context, 'Only admins can edit categories',
          isError: true);
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
        flexibleSpace: Theme.of(context).brightness == Brightness.dark
            ? Container(color: const Color(0xFF1E1E1E))
            : Container(
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
            icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CategorySearchDelegate(),
              );
            },
          ),
          if (userRole == 'admin')
            IconButton(
              icon: Icon(Icons.add, color: Theme.of(context).iconTheme.color),
              tooltip: 'Add Category',
              onPressed: () => addCategory(context),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categories').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.blueAccent,
              ),
            );
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
                    physics: const BouncingScrollPhysics(),
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
            ],
          );
        },
      ),
    );
  }
}
