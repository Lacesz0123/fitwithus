import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/recipes/recipe_detail_screen.dart';

class FavoriteRecipesScreen extends StatelessWidget {
  const FavoriteRecipesScreen({Key? key}) : super(key: key);

  Future<List<DocumentSnapshot>> _getFavoriteRecipes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final List<dynamic> favorites = userDoc['favoriteRecipes'] ?? [];

      // Szűrjük ki az üres stringeket a kedvencek közül
      final List<String> validFavorites = favorites
          .where((recipeId) => recipeId is String && recipeId.isNotEmpty)
          .toList()
          .cast<String>();

      // A kedvenc receptek beolvasása az érvényes azonosítók alapján
      if (validFavorites.isNotEmpty) {
        final recipes = await FirebaseFirestore.instance
            .collection('recipes')
            .where(FieldPath.documentId, whereIn: validFavorites)
            .get();
        return recipes.docs;
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorite Recipes"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.tealAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _getFavoriteRecipes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading favorite recipes"));
          }
          final recipes = snapshot.data ?? [];
          if (recipes.isEmpty) {
            return const Center(child: Text("No favorite recipes found"));
          }

          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              var recipeData = recipes[index].data() as Map<String, dynamic>;
              String recipeName = recipeData['name'] ?? "Unknown Recipe";
              String? imageUrl = recipeData['imageUrl'];

              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => RecipeDetailScreen(
                        recipeId: recipes[index].id,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageUrl != null
                            ? Image.network(
                                imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                Icons.fastfood,
                                size: 60,
                                color: Colors.grey,
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          recipeName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
