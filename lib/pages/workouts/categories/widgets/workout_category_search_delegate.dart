import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../pages/workouts/in_a_category/in_a_category_list_workouts_screen.dart';
import 'dart:io';

/// A `SearchDelegate` egyedi implementációja, amely lehetővé teszi az edzéskategóriák keresését.
///
/// A keresés `title_lower` mező alapján történik, kisbetűs formában.
/// A találatok listaként jelennek meg, ahol minden elemre kattintva az adott
/// kategória edzései jelennek meg (`CategoryWorkoutsScreen`).
class CategorySearchDelegate extends SearchDelegate {
  /// Keresősáv melletti „törlés” ikon.
  /// Megnyomására kiürül a keresőkifejezés (`query = ''`).
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

  /// A keresőpanel bal oldalán lévő vissza nyíl.
  /// Bezárja a keresőt (`close(context, null)`).
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  /// Keresési találatok lekérése és megjelenítése:
  /// - Először internetkapcsolat ellenőrzés
  /// - Majd Firestore-ból kisbetűs `title_lower` mező alapján lekérdezés
  /// - A találatok listában jelennek meg, képpel együtt (ha van internet)
  ///
  /// Minden találatra kattintva navigál az adott kategória edzéseihez.
  @override
  Widget buildResults(BuildContext context) {
    String lowerCaseQuery = query.toLowerCase();

    return FutureBuilder<bool>(
      future: _checkInternet(),
      builder: (context, internetSnapshot) {
        if (!internetSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blueAccent),
          );
        }

        final hasInternet = internetSnapshot.data!;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('categories')
              .where('title_lower', isGreaterThanOrEqualTo: lowerCaseQuery)
              .where('title_lower',
                  isLessThanOrEqualTo: lowerCaseQuery + '\uf8ff')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              );
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
                  leading: hasInternet && categoryImage.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            categoryImage,
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
      },
    );
  }

  /// A javaslatok és találatok ugyanazt a nézetet használják.
  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }

  /// Ellenőrzi, hogy van-e aktív internetkapcsolat a `example.com` segítségével.
  ///
  /// Ez alapján döntjük el, hogy online képeket töltünk-e be vagy offline helyettesítő képet.
  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
