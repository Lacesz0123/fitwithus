import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../../utils/custom_snackbar.dart';

class AddRecipeScreen extends StatefulWidget {
  final String category;

  const AddRecipeScreen({Key? key, required this.category}) : super(key: key);

  @override
  _AddRecipeScreenState createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController prepTimeController = TextEditingController();
  final TextEditingController caloriesController = TextEditingController();

  List<TextEditingController> ingredientControllers = [TextEditingController()];
  List<TextEditingController> stepControllers = [TextEditingController()];

  File? _selectedImage;
  bool _isLoading = false;

  Color get primaryColor => Theme.of(context).brightness == Brightness.light
      ? Colors.blueAccent
      : Colors.grey.shade700;

  Color get textColor => Theme.of(context).brightness == Brightness.light
      ? Colors.black87
      : Colors.white;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('recipe_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

    await storageRef.putFile(_selectedImage!);
    return await storageRef.getDownloadURL();
  }

  Future<void> _addRecipe() async {
    if (nameController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        prepTimeController.text.isEmpty ||
        caloriesController.text.isEmpty ||
        ingredientControllers.any((c) => c.text.isEmpty) ||
        stepControllers.any((c) => c.text.isEmpty) ||
        _selectedImage == null) {
      showCustomSnackBar(context, "Please fill all fields and upload an image.",
          isError: true);
      return;
    }

    int? calories = int.tryParse(caloriesController.text);
    if (calories == null || calories <= 0) {
      showCustomSnackBar(context, "Calories must be a valid positive number.",
          isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageUrl = await _uploadImage();

      List<String> ingredients = ingredientControllers
          .map((controller) => controller.text)
          .where((text) => text.isNotEmpty)
          .toList();
      List<String> steps = stepControllers
          .map((controller) => controller.text)
          .where((text) => text.isNotEmpty)
          .toList();

      await FirebaseFirestore.instance.collection('recipes').add({
        'name': nameController.text,
        'name_lower': nameController.text.toLowerCase(),
        'description': descriptionController.text,
        'prepTime': int.parse(prepTimeController.text),
        'difficulty': widget.category,
        'ingredients': ingredients,
        'steps': steps,
        'imageUrl': imageUrl,
        'calories': calories,
      });

      Navigator.of(context).pop();
      showCustomSnackBar(context, "Recipe added successfully!");
    } catch (e) {
      showCustomSnackBar(context, "Failed to add recipe: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildLabeledField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
            fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Recipe"),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : null,
        flexibleSpace: Theme.of(context).brightness == Brightness.light
            ? Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent, Colors.tealAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabeledField("Recipe Name", nameController),
                  _buildLabeledField("Description", descriptionController,
                      maxLines: 4),
                  _buildLabeledField(
                      "Preparation Time (minutes)", prepTimeController,
                      keyboardType: TextInputType.number),
                  _buildLabeledField("Calories (kcal)", caloriesController,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _selectedImage!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text("No image selected",
                              style: TextStyle(color: textColor)),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.upload, color: Colors.white),
                        label: const Text('Select Image',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text("Ingredients",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor)),
                  const SizedBox(height: 10),
                  ...ingredientControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                labelText: "Ingredient",
                                labelStyle: TextStyle(color: textColor),
                                fillColor: Theme.of(context)
                                    .colorScheme
                                    .surface
                                    .withOpacity(0.1),
                                filled: true,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                ingredientControllers.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          ingredientControllers.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Add Ingredient',
                          style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text("Steps",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor)),
                  const SizedBox(height: 10),
                  ...stepControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                labelText: "Step ${index + 1}",
                                labelStyle: TextStyle(color: textColor),
                                fillColor: Theme.of(context)
                                    .colorScheme
                                    .surface
                                    .withOpacity(0.1),
                                filled: true,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                stepControllers.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          stepControllers.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Add Step',
                          style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _addRecipe,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text("Add Recipe",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    prepTimeController.dispose();
    caloriesController.dispose();
    ingredientControllers.forEach((controller) => controller.dispose());
    stepControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }
}
