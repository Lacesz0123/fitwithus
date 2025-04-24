import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'widgets/detail_recipe_header.dart';
import 'widgets/detail_recipe_ingredients_checklist.dart';
import 'widgets/detail_recipe_steps.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({Key? key, required this.recipeId})
      : super(key: key);

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Map<String, bool> ingredientsStatus = {};
  String name = '';
  String description = '';
  int prepTime = 0;
  List<String> steps = [];
  bool isFavorite = false;
  String? imageUrl;
  int? calories;
  bool isGuest = false;

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
    _checkIfFavorite();
    _checkIfGuest();
  }

  Future<void> _checkIfGuest() async {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      isGuest = user?.isAnonymous ?? false;
    });
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
      imageUrl = data['imageUrl'];
      calories = data['calories'];
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

  Future<void> _addRecipeCaloriesToDaily() async {
    if (calories == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userDoc = await userRef.get();
    final data = userDoc.data();

    final currentCalories = data?['dailyCalories'] ?? 0;
    await userRef.set({'dailyCalories': currentCalories + calories!},
        SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Calories updated!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blueAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recipe Details"),
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
      ),
      body: name.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RecipeHeader(
                    name: name,
                    isFavorite: isFavorite,
                    prepTime: prepTime,
                    calories: calories,
                    description: description,
                    onToggleFavorite: _toggleFavorite,
                    showFavoriteButton: !isGuest,
                  ),
                  const SizedBox(height: 20),
                  IngredientChecklist(
                    ingredientsStatus: ingredientsStatus,
                    onToggle: _toggleIngredientStatus,
                  ),
                  const SizedBox(height: 20),
                  if (imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        imageUrl!,
                        height: 230,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  RecipeSteps(steps: steps),
                ],
              ),
            ),
      bottomNavigationBar: !isGuest && calories != null
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _addRecipeCaloriesToDaily,
                icon: const Icon(Icons.restaurant, color: Colors.white),
                label: const Text(
                  "I ate this",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.light
                          ? Colors.blueAccent
                          : Colors.blueGrey.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
