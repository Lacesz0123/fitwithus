import 'dart:io';
import 'package:flutter/material.dart';

class EditRecipeHeader extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController caloriesController;
  final TextEditingController prepTimeController;
  final File? selectedImage;
  final String? imageUrl;
  final VoidCallback onImagePick;

  const EditRecipeHeader({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.caloriesController,
    required this.prepTimeController,
    required this.selectedImage,
    required this.imageUrl,
    required this.onImagePick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: "Recipe Name",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: "Description",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: caloriesController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Calories (kcal)",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: prepTimeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Preparation Time (minutes)",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      selectedImage!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                : (imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          imageUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Text("No image selected")),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: onImagePick,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Select Image"),
            ),
          ],
        ),
      ],
    );
  }
}
