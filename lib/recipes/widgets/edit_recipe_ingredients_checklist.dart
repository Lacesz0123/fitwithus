import 'package:flutter/material.dart';

class EditRecipeIngredients extends StatelessWidget {
  final List<TextEditingController> controllers;
  final VoidCallback onChanged;
  final VoidCallback onAddIngredient;
  final Function(int) onRemoveIngredient;

  const EditRecipeIngredients({
    Key? key,
    required this.controllers,
    required this.onChanged,
    required this.onAddIngredient,
    required this.onRemoveIngredient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ingredients",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...controllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: "Ingredient"),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => onRemoveIngredient(index),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: onAddIngredient,
          icon: const Icon(Icons.add_circle, color: Colors.teal),
          label: const Text("Add Ingredient"),
        ),
      ],
    );
  }
}
