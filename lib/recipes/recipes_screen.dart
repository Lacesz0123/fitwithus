import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'recipe_detail_screen.dart';
import 'add_recipe_screen.dart';
import 'edit_recipe_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({Key? key}) : super(key: key);

  @override
  _RecipesScreenState createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC), // Világos szürke háttér
      appBar: AppBar(
        title: const Text("Healthy Recipes"),
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
                delegate: RecipeSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('recipes').snapshots(),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent, // Színes háttér
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Text(
                            difficulty,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // Fehér szöveg
                            ),
                          ),
                        ),
                        if (userRole == 'admin')
                          IconButton(
                            icon:
                                const Icon(Icons.add, color: Colors.blueAccent),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Stack(
                            children: [
                              GestureDetector(
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
                                    color: Colors.white, // Világos színű kártya
                                    elevation: 2.0, // Csökkentett árnyék
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          20.0), // Nagyobb lekerekítés
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
                                                  BorderRadius.circular(15.0),
                                              child: Image.network(
                                                imageUrl,
                                                height: 90,
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
                                                color: Colors
                                                    .black87, // Fekete szöveg
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
                                              EditRecipeScreen(
                                                  recipeId: recipes[index].id),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
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
  }
}

// Keresési funkció implementálása kis-nagybetű különbség nélkül
class RecipeSearchDelegate extends SearchDelegate {
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
    String lowerCaseQuery = query.toLowerCase();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recipes')
          .where('name_lower', isGreaterThanOrEqualTo: lowerCaseQuery)
          .where('name_lower', isLessThanOrEqualTo: lowerCaseQuery + '')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No recipes found"));
        }

        List<QueryDocumentSnapshot> recipes = snapshot.data!.docs;

        return ListView.builder(
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            var recipeData = recipes[index].data() as Map<String, dynamic>;
            String recipeName = recipeData['name'] ?? "Unknown Recipe";
            String? imageUrl = recipeData['imageUrl'];

            return ListTile(
              leading: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.fastfood, size: 40),
              title: Text(recipeName),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RecipeDetailScreen(
                      recipeId: recipes[index].id,
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
