import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../in_a_category/In_a_category_list_workouts_screen.dart';

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
      onPressed: () => close(context, null),
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
                      child: Image.network(
                        categoryImage,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
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
