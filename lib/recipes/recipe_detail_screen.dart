import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeDetailScreen extends StatelessWidget {
  final String recipeId;

  RecipeDetailScreen({required this.recipeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recipe Details")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('recipes')
            .doc(recipeId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Recipe not found"));
          }

          // Recept adatok kinyerése
          var data = snapshot.data!.data() as Map<String, dynamic>;
          String name = data['name'];
          String description = data['description'] ?? '';
          int prepTime = data['prepTime'];
          List<String> ingredients = List<String>.from(data['ingredients']);
          List<String> steps = List<String>.from(data['steps']);

          return SingleChildScrollView(
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
                Column(
                  children: ingredients.map((ingredient) {
                    return CheckboxListTile(
                      title: Text(ingredient),
                      value: false, // Kezdetben nincs kipipálva
                      onChanged: (bool? value) {},
                    );
                  }).toList(),
                ),

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
                      child:
                          Text("- $step", style: const TextStyle(fontSize: 16)),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
