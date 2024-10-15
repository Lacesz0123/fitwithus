import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'category_workouts_screen.dart'; // Az általános edzések listázó képernyő importálása

class WorkoutsScreen extends StatelessWidget {
  WorkoutsScreen({super.key});

  // Kategóriák lekérdezése a Firestore-ból
  Future<List<Map<String, dynamic>>> getCategories() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('categories').get();

    return querySnapshot.docs.map((doc) {
      return doc.data() as Map<String, dynamic>;
    }).toList();
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
                crossAxisCount: 2, // 2 oszlopos rács
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 1.0, // A rács négyzetszerű elrendezése
              ),
              itemCount: categories.length,
              itemBuilder: (BuildContext context, int index) {
                String categoryTitle = categories[index]['title'] ?? 'No title';
                String categoryImage = categories[index]['image'] ?? '';

                return GestureDetector(
                  onTap: () {
                    // Navigálás a megfelelő kategóriához tartozó edzések listájára
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
                            ? AssetImage(categoryImage)
                            : const AssetImage('assets/placeholder.jpg'),
                        fit: BoxFit.cover, // A kép kitölti a konténert
                      ),
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        color: Colors.black54, // Félig átlátszó fekete háttér
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
                );
              },
            ),
          );
        },
      ),
    );
  }
}
