import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'add_recipe_screen.dart';
import '../widgets/recipe_card.dart';
import '../widgets/recipe_search_delegate.dart';

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
      backgroundColor: const Color(0xFFF7F9FC),
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

          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            String difficulty = data['difficulty'] ?? "Easy";

            if (categorizedRecipes.containsKey(difficulty)) {
              categorizedRecipes[difficulty]!.add(doc);
            }
          }

          return ListView(
            children: categorizedRecipes.entries.map((entry) {
              String difficulty = entry.key;
              List<DocumentSnapshot> recipes = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            difficulty,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                        return RecipeCard(
                          recipe: recipes[index],
                          userRole: userRole ?? '',
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
