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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.grey.shade300 : Colors.blueAccent;
    final inputFillColor = isDark ? Colors.grey.shade800 : Colors.grey[100];
    final textColor = isDark ? Colors.white : Colors.black87;

    Widget buildLabel(String text) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      );
    }

    InputDecoration buildInputDecoration(String hint) {
      return InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: inputFillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel('Recipe Name'),
        const SizedBox(height: 6),
        TextField(
          controller: nameController,
          decoration: buildInputDecoration('Enter recipe name'),
        ),
        const SizedBox(height: 20),
        buildLabel('Description'),
        const SizedBox(height: 6),
        TextField(
          controller: descriptionController,
          maxLines: 3,
          decoration: buildInputDecoration('Enter description'),
        ),
        const SizedBox(height: 20),
        buildLabel('Calories (kcal)'),
        const SizedBox(height: 6),
        TextField(
          controller: caloriesController,
          keyboardType: TextInputType.number,
          decoration: buildInputDecoration('e.g. 250'),
        ),
        const SizedBox(height: 20),
        buildLabel('Preparation Time (minutes)'),
        const SizedBox(height: 6),
        TextField(
          controller: prepTimeController,
          keyboardType: TextInputType.number,
          decoration: buildInputDecoration('e.g. 15'),
        ),
        const SizedBox(height: 24),
        buildLabel('Image'),
        const SizedBox(height: 8),
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: selectedImage != null
                  ? Image.file(
                      selectedImage!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    )
                  : (imageUrl != null
                      ? Image.network(
                          imageUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          color:
                              isDark ? Colors.grey.shade700 : Colors.grey[200],
                          child: Icon(Icons.image_not_supported,
                              color: Colors.grey.shade500),
                        )),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: onImagePick,
              icon: const Icon(Icons.upload, color: Colors.white),
              label: const Text('Select Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? Colors.grey.shade700 : Colors.blueAccent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
