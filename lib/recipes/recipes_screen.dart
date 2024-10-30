import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'recipe_detail_screen.dart';
import 'add_recipe_screen.dart'; // Az új hozzáadási képernyő importálása

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  // Ellenőrzi, hogy a felhasználó admin-e
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

              // Recept lista csoportosítva nehézségi szint szerint
              Map<String, List<DocumentSnapshot>> categorizedRecipes = {
                "Easy": [],
                "Intermediate": [],
                "Advanced": [],
              };

              // A Firestore adatainak feldolgozása
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
                      // Kategória címsor "Add" gombbal
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
                      // Recept kártyák
                      SizedBox(
                        height: 150, // Fixált magasság a vízszintes görgetéshez
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: recipes.length,
                          itemBuilder: (context, index) {
                            var recipeData =
                                recipes[index].data() as Map<String, dynamic>;
                            String recipeName =
                                recipeData['name'] ?? "Unknown Recipe";

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
                                child: Card(
                                  elevation: 4.0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  child: Container(
                                    width: 200,
                                    padding: const EdgeInsets.all(10.0),
                                    child: Center(
                                      child: Text(
                                        recipeName,
                                        style: const TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
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
