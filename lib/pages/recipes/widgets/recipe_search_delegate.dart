import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../recipe_detail_screen.dart';
import 'dart:io';

/// A `RecipeSearchDelegate` egy keresési felület receptek kereséséhez a Firestore adatbázisból.
///
/// A `SearchDelegate` alosztályaként működik, lehetővé téve a felhasználók számára,
/// hogy valós időben keressenek recepteket a nevük alapján (`name_lower` mező).
///
/// ## Főbb jellemzők:
/// - **Valós idejű keresés**: A keresés automatikusan frissül a beírt lekérdezés (`query`) alapján.
/// - **Offline kezelés**: Ha nincs internetkapcsolat, a keresés ettől függetlenül lefut,
///   de a recept képek helyett egy `offline_placeholder.png` asset kerül megjelenítésre.
/// - **Lekérdezési feltétel**: A keresés `where` feltételeken keresztül történik a Firestore-ban,
///   a `name_lower` mező használatával, hogy kis- és nagybetűket figyelmen kívül hagyjon.
///
/// ## Fő metódusok:
/// - `buildActions`: A keresősáv műveleteit jeleníti meg, például a keresési mező törlését.
/// - `buildLeading`: Vissza gomb a keresési képernyő bezárásához.
/// - `buildResults`: A találatok megjelenítése a lekérdezés alapján. `StreamBuilder`
///   segítségével figyeli a `recipes` kollekció változásait.
/// - `buildSuggestions`: Ugyanazt a logikát használja, mint a `buildResults`.
///
/// ## Technikai megjegyzés:
/// - A `name_lower` mező az adatbázisban külön mezőként szerepel, amely a recept nevét
///   kisbetűs formában tárolja, hogy hatékony legyen a keresés.
///
/// Ez az osztály reszponzív és robusztus keresési élményt nyújt egy Flutter-alapú
/// receptalkalmazásban.
class RecipeSearchDelegate extends SearchDelegate {
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
    final lowerCaseQuery = query.toLowerCase();

    return FutureBuilder<bool>(
      future: _hasInternet(),
      builder: (context, internetSnapshot) {
        if (!internetSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blueAccent),
          );
        }

        final hasInternet = internetSnapshot.data!;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('recipes')
              .where('name_lower', isGreaterThanOrEqualTo: lowerCaseQuery)
              .where('name_lower', isLessThanOrEqualTo: '$lowerCaseQuery')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No recipes found"));
            }

            final recipes = snapshot.data!.docs;

            return ListView.builder(
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index].data() as Map<String, dynamic>;
                final name = recipe['name'] ?? 'Unknown Recipe';
                final imageUrl = recipe['imageUrl'];
                final id = recipes[index].id;

                return ListTile(
                  leading:
                      hasInternet && imageUrl != null && imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/offline_placeholder.png',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/offline_placeholder.png',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                  title: Text(name),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RecipeDetailScreen(recipeId: id),
                      ),
                    );
                  },
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

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
