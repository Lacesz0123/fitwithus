import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'add_recipe_screen.dart';
import 'widgets/recipe_card.dart';
import 'widgets/recipe_search_delegate.dart';

/// A [RecipesScreen] képernyő receptkártyák böngészésére és kategorizált megjelenítésére szolgál.
///
/// ## Főbb funkciók:
/// - Receptadatok valós idejű megjelenítése a `recipes` Firestore kollekcióból.
/// - A receptek `difficulty` mező alapján három kategóriába sorolva jelennek meg: `Easy`, `Intermediate`, `Advanced`.
/// - Kategóriánként GridView formátumban jelennek meg a receptek.
/// - A keresés `RecipeSearchDelegate` használatával történik, amelyet az AppBar keresőikonja indít.
/// - Adminisztrátori szerepkör esetén a kategóriák mellett `+` gomb jelenik meg, amely új recept hozzáadását teszi lehetővé adott kategóriába.
///
/// ## Technikai részletek:
/// - A felhasználó szerepköre (`role`) Firestore `users` kollekciójából kerül betöltésre a `currentUser.uid` alapján.
/// - Az `initState()` metódus betölti az aktuális felhasználó szerepkörét.
/// - A receptek StreamBuilder segítségével valós időben frissülnek.
/// - A `GridView.builder` a `NeverScrollableScrollPhysics`-el van beállítva, így nem scrollozik külön – a `ListView` görgeti az egész oldalt.
///
/// ## UI sajátosságok:
/// - Világos és sötét mód támogatás.
/// - Modern, anyagszerű dizájn lekerekített gombokkal és színezett címkékkel.
/// - Animált keresőfelület és reszponzív GridView receptmegjelenítés.
///
/// Ez az osztály ideális kiindulási alap egy egészséges életmóddal kapcsolatos receptböngésző képernyőhöz, amely Firebase integrációt használ Flutter alkalmazásban.
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Healthy Recipes"),
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
            icon: Icon(
              Icons.search,
              color: Theme.of(context).iconTheme.color,
            ),
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
            return const SizedBox(
              height: 400,
              child: Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              ),
            );
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
            physics: const BouncingScrollPhysics(),
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
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.blueGrey.shade900
                                    : Colors.blueAccent,
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
                            icon: Icon(
                              Icons.add,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.blueAccent,
                            ),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: recipes.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 0.1,
                        crossAxisSpacing: 0.1,
                        childAspectRatio: 1,
                      ),
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
