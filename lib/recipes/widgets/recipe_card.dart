import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../recipe_detail_screen.dart';
import '../edit_recipe_screen.dart';

class RecipeCard extends StatelessWidget {
  final DocumentSnapshot recipe;
  final String userRole;

  const RecipeCard({super.key, required this.recipe, required this.userRole});

  @override
  Widget build(BuildContext context) {
    final data = recipe.data() as Map<String, dynamic>;
    final recipeName = data['name'] ?? "Unknown Recipe";
    final imageUrl = data['imageUrl'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RecipeDetailScreen(recipeId: recipe.id),
                ),
              );
            },
            child: SizedBox(
              width: 200,
              child: Card(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.blueGrey.shade900
                    : Colors.white,
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl != null)
                        ClipRRect(
                            borderRadius: BorderRadius.circular(15.0),
                            child: Image.network(
                              imageUrl,
                              height: 90,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (BuildContext context,
                                  Widget child,
                                  ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                } else {
                                  return Container(
                                    height: 90,
                                    width: double.infinity,
                                    color: Theme.of(context).cardColor,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.blueAccent,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                              errorBuilder: (context, error, stackTrace) {
                                final isDark = Theme.of(context).brightness ==
                                    Brightness.dark;
                                return Container(
                                  height: 90,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.grey[900]
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(15),
                                    image: const DecorationImage(
                                      image: AssetImage(
                                          'assets/offline_placeholder.png'), // ← ez legyen a helyettesítő kép
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  alignment: Alignment.bottomCenter,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 4),
                                );
                              },
                            )),
                      const SizedBox(height: 8),
                      Flexible(
                        child: Text(
                          recipeName,
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
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
          if (userRole == 'admin')
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          EditRecipeScreen(recipeId: recipe.id),
                    ),
                  );
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6.0),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 24.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
