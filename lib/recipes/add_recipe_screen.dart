import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddRecipeScreen extends StatefulWidget {
  final String category; // A kiválasztott kategória neve

  const AddRecipeScreen({Key? key, required this.category}) : super(key: key);

  @override
  _AddRecipeScreenState createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController prepTimeController = TextEditingController();
  final TextEditingController ingredientsController = TextEditingController();
  final TextEditingController stepsController = TextEditingController();

  Future<void> _addRecipe() async {
    if (nameController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty &&
        prepTimeController.text.isNotEmpty &&
        ingredientsController.text.isNotEmpty &&
        stepsController.text.isNotEmpty) {
      // Tördeljük a hozzávalókat és lépéseket listává
      List<String> ingredients = ingredientsController.text.split(',');
      List<String> steps = stepsController.text.split(',');

      await FirebaseFirestore.instance.collection('recipes').add({
        'name': nameController.text,
        'description': descriptionController.text,
        'prepTime': int.parse(prepTimeController.text),
        'difficulty': widget.category, // A kiválasztott kategória
        'ingredients': ingredients,
        'steps': steps
      });

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Recipe")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Recipe Name"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: prepTimeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: "Preparation Time (minutes)"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ingredientsController,
              decoration: const InputDecoration(
                labelText: "Ingredients (comma separated)",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: stepsController,
              decoration: const InputDecoration(
                labelText: "Steps (comma separated)",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addRecipe,
              child: const Text("Add Recipe"),
            ),
          ],
        ),
      ),
    );
  }
}
