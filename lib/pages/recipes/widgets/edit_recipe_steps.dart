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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.grey.shade300 : Colors.blueAccent;
    final fillColor = isDark ? Colors.grey.shade800 : Colors.grey[100];
    final textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Steps",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controllers.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controllers[index],
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Step ${index + 1}',
                        labelStyle: TextStyle(color: textColor),
                        filled: true,
                        fillColor: fillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => onRemoveStep(index),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Center(
          child: OutlinedButton.icon(
            onPressed: onAddStep,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Step'),
            style: OutlinedButton.styleFrom(
              backgroundColor:
                  isDark ? Colors.grey.shade700 : Colors.blueAccent,
              foregroundColor: Colors.white,
              side: BorderSide(color: primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
