import 'package:flutter/material.dart';

class EditRecipeSteps extends StatelessWidget {
  final List<TextEditingController> controllers;
  final VoidCallback onChanged;
  final VoidCallback onAddStep;
  final Function(int) onRemoveStep;

  const EditRecipeSteps({
    Key? key,
    required this.controllers,
    required this.onChanged,
    required this.onAddStep,
    required this.onRemoveStep,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Steps",
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
                    decoration: InputDecoration(labelText: "Step ${index + 1}"),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => onRemoveStep(index),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: onAddStep,
          icon: const Icon(Icons.add_circle, color: Colors.teal),
          label: const Text("Add Step"),
        ),
      ],
    );
  }
}
