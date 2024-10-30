import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'recipe_detail_screen.dart';
import 'add_recipe_screen.dart';

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  Future<bool> _isAdmin() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      return data?['role'] == "admin";
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, snapshot) {
        bool isAdmin = snapshot.data ?? false;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Healthy Recipes"),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('recipes').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No recipes available"));
              }

              Map<String, List<DocumentSnapshot>> categorizedRecipes = {
                "Easy": [],
                "Intermediate": [],
                "Advanced": [],
              };

              snapshot.data!.docs.forEach((doc) {
                var data = doc.data() as Map<String, dynamic>;
                String difficulty = data['difficulty'] ?? "Easy";

                if (categorizedRecipes.containsKey(difficulty)) {
                  categorizedRecipes[difficulty]!.add(doc);
                }
              });

              return ListView(
                children: categorizedRecipes.entries.map((entry) {
                  String difficulty = entry.key;
                  List<DocumentSnapshot> recipes = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              difficulty,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isAdmin)
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AddRecipeScreen(category: difficulty),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: recipes.length,
                          itemBuilder: (context, index) {
                            var recipeData =
                                recipes[index].data() as Map<String, dynamic>;
                            String recipeName =
                                recipeData['name'] ?? "Unknown Recipe";
                            String? imageUrl = recipeData['imageUrl'];

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => RecipeDetailScreen(
                                          recipeId: recipes[index].id),
                                    ),
                                  );
                                },
                                child: SizedBox(
                                  width: 200,
                                  child: Card(
                                    elevation: 4.0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (imageUrl != null)
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              child: Image.network(
                                                imageUrl,
                                                height:
                                                    90, // Adjusted height for balance
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          const SizedBox(height: 8),
                                          Flexible(
                                            child: Text(
                                              recipeName,
                                              style: const TextStyle(
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        );
      },
    );
  }
}
