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
  late Map<String, bool> ingredientsStatus = {};
  String name = '';
  String description = '';
  int prepTime = 0;
  List<String> steps = [];
  bool isFavorite = false;
  String? imageUrl; // Kép URL hozzáadása
  int? calories; // Kalóriaérték tárolása

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
      imageUrl = data['imageUrl']; // Kép URL lekérése
      ingredientsStatus = {
        for (var ingredient in ingredients) ingredient: false
      };
      calories = data['calories']; // Kalóriaérték lekérése
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
      body: name.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleFavorite,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: isFavorite
                                ? Colors.yellow.shade100
                                : Colors.grey.shade200,
                            shape: BoxShape.circle,
                            boxShadow: [
                              if (isFavorite)
                                BoxShadow(
                                  color: Colors.yellow.shade400,
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            isFavorite ? Icons.star : Icons.star_border,
                            color: isFavorite ? Colors.orange : Colors.grey,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        "Preparation Time: $prepTime minutes",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  // Kalóriaérték hozzáadása a build metódushoz
                  const SizedBox(height: 12),
                  if (calories != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department,
                            color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          "Calories: $calories kcal",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Text(
                    "Ingredients:",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...ingredientsStatus.keys.map((ingredient) {
                    bool isChecked = ingredientsStatus[ingredient] ?? false;
                    return CheckboxListTile(
                      title: Text(
                        ingredient,
                        style: TextStyle(
                          fontSize: 16,
                          color: isChecked ? Colors.grey : Colors.black,
                          decoration: isChecked
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      value: isChecked,
                      onChanged: (_) => _toggleIngredientStatus(ingredient),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: Colors.teal,
                      checkColor: Colors.white,
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  const Text(
                    "Steps:",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...steps.asMap().entries.map((entry) {
                    int index = entry.key + 1;
                    String step = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$index. ",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              step,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                  if (imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        imageUrl!,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
