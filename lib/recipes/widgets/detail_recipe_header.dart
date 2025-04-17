// lib/recipes/widgets/recipe_header.dart

import 'package:flutter/material.dart';

class RecipeHeader extends StatelessWidget {
  final String name;
  final int prepTime;
  final String description;
  final int? calories;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const RecipeHeader({
    super.key,
    required this.name,
    required this.prepTime,
    required this.description,
    required this.calories,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
                  color: Colors.blueAccent,
                ),
              ),
            ),
            GestureDetector(
              onTap: onToggleFavorite,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: isFavorite
                      ? Colors.yellow.shade100
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                  boxShadow: isFavorite
                      ? [
                          BoxShadow(
                            color: Colors.yellow.shade400,
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
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
        if (calories != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                "Calories: $calories kcal",
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
