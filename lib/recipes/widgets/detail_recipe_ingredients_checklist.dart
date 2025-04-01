import 'package:flutter/material.dart';

class IngredientChecklist extends StatelessWidget {
  final Map<String, bool> ingredientsStatus;
  final void Function(String ingredient) onToggle;

  const IngredientChecklist({
    super.key,
    required this.ingredientsStatus,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          final isChecked = ingredientsStatus[ingredient] ?? false;
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
            onChanged: (_) => onToggle(ingredient),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: Colors.teal,
            checkColor: Colors.white,
          );
        }).toList(),
      ],
    );
  }
}
