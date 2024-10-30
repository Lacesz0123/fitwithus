import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({Key? key, required this.recipeId})
      : super(key: key);

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Map<String, bool> ingredientsStatus = {}; // Hozzávalók állapotai
  String name = '';
  String description = '';
  int prepTime = 0;
  List<String> steps = [];
  bool isFavorite = false; // Kedvenc állapot

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
    _checkIfFavorite();
  }

  Future<void> _fetchRecipeDetails() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('recipes')
        .doc(widget.recipeId)
        .get();

    var data = doc.data() as Map<String, dynamic>;
    List<String> ingredients = List<String>.from(data['ingredients']);

    setState(() {
      name = data['name'];
      description = data['description'] ?? '';
      prepTime = data['prepTime'];
      steps = List<String>.from(data['steps']);
      ingredientsStatus = {
        for (var ingredient in ingredients) ingredient: false
      };
    });
  }

  Future<void> _checkIfFavorite() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      List<dynamic> favoriteRecipes = userDoc['favoriteRecipes'] ?? [];
      setState(() {
        isFavorite = favoriteRecipes.contains(widget.recipeId);
      });
    }
  }

  Future<void> _toggleFavorite() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    setState(() {
      isFavorite = !isFavorite;
    });

    if (isFavorite) {
      await userRef.update({
        'favoriteRecipes': FieldValue.arrayUnion([widget.recipeId])
      });
    } else {
      await userRef.update({
        'favoriteRecipes': FieldValue.arrayRemove([widget.recipeId])
      });
    }
  }

  void _toggleIngredientStatus(String ingredient) {
    setState(() {
      ingredientsStatus[ingredient] = !(ingredientsStatus[ingredient] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recipe Details"),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Colors.yellow : Colors.grey,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: name.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Preparation Time: $prepTime minutes",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),

                  // Hozzávalók lista jelölőnégyzetekkel
                  const Text("Ingredients:",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...ingredientsStatus.keys.map((ingredient) {
                    bool isChecked = ingredientsStatus[ingredient] ?? false;
                    return CheckboxListTile(
                      title: Text(ingredient),
                      value: isChecked,
                      onChanged: (_) => _toggleIngredientStatus(ingredient),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: Colors.green,
                      checkColor: Colors.white,
                    );
                  }).toList(),

                  const SizedBox(height: 16),

                  // Lépések megjelenítése
                  const Text("Steps:",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: steps.map((step) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text("- $step",
                            style: const TextStyle(fontSize: 16)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
    );
  }
}
