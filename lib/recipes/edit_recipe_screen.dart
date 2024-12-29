import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditRecipeScreen extends StatefulWidget {
  final String recipeId;

  const EditRecipeScreen({Key? key, required this.recipeId}) : super(key: key);

  @override
  _EditRecipeScreenState createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController caloriesController = TextEditingController();
  final TextEditingController prepTimeController = TextEditingController();
  List<TextEditingController> ingredientControllers = [];
  List<TextEditingController> stepControllers = [];
  File? _selectedImage;
  String? _imageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
    _loadRecipeData();
  }

  void _checkAdminRole() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser?.uid)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        var data = documentSnapshot.data() as Map<String, dynamic>;
        if (data['role'] != 'admin') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Only admins can edit recipes.')),
          );
          Navigator.of(context).pop();
        }
      }
    });
  }

  Future<void> _loadRecipeData() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('recipes')
        .doc(widget.recipeId)
        .get();
    var data = doc.data() as Map<String, dynamic>;

    setState(() {
      nameController.text = data['name'];
      descriptionController.text = data['description'];
      prepTimeController.text = data['prepTime'].toString();
      _imageUrl = data['imageUrl'];
      ingredientControllers = (data['ingredients'] as List<dynamic>)
          .map((ingredient) => TextEditingController(text: ingredient))
          .toList();
      stepControllers = (data['steps'] as List<dynamic>)
          .map((step) => TextEditingController(text: step))
          .toList();
      if (data['calories'] != null) {
        caloriesController.text = data['calories'].toString();
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.length();
      if (bytes > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image size cannot exceed 5MB.")),
        );
        return;
      }
      setState(() {
        _selectedImage = file;
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return _imageUrl;

    if (_imageUrl != null) {
      try {
        final oldImageRef = FirebaseStorage.instance.refFromURL(_imageUrl!);
        await oldImageRef.delete();
      } catch (e) {
        print('Error deleting previous image from Storage: $e');
      }
    }

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('recipe_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await storageRef.putFile(_selectedImage!);
    return await storageRef.getDownloadURL();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (nameController.text.isEmpty) {
        _showError('Recipe name cannot be empty.');
        return;
      }

      if (descriptionController.text.isEmpty) {
        _showError('Description cannot be empty.');
        return;
      }

      int? prepTime = int.tryParse(prepTimeController.text);
      if (prepTime == null) {
        _showError('Preparation time must be a valid number.');
        return;
      }

      int? calories = int.tryParse(caloriesController.text);
      if (calories == null || calories <= 0) {
        _showError('Calories must be a valid positive number.');
        return;
      }

      List<String> ingredients = ingredientControllers
          .map((controller) => controller.text)
          .where((text) => text.isNotEmpty)
          .toList();
      if (ingredients.isEmpty) {
        _showError('Please add at least one ingredient.');
        return;
      }

      List<String> steps = stepControllers
          .map((controller) => controller.text)
          .where((text) => text.isNotEmpty)
          .toList();
      if (steps.isEmpty) {
        _showError('Please add at least one step.');
        return;
      }

      final imageUrl = await _uploadImage();

      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipeId)
          .update({
        'name': nameController.text,
        'description': descriptionController.text,
        'prepTime': prepTime,
        'ingredients': ingredients,
        'steps': steps,
        'imageUrl': imageUrl ?? _imageUrl,
        'calories': calories, // Kalóriaérték mentése
      });

      Navigator.of(context).pop();
    } catch (e) {
      _showError('Failed to save changes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Recipe"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.tealAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: _isLoading ? null : _confirmDeleteRecipe,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
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
                          : (_imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    _imageUrl!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Text("No image selected")),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _pickImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Select Image"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("Ingredients",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ...ingredientControllers.map((controller) {
                    int index = ingredientControllers.indexOf(controller);
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                    labelText: "Ingredient"),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle),
                              color: Colors.red,
                              onPressed: () {
                                setState(() {
                                  ingredientControllers.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10), // Extra távolság
                      ],
                    );
                  }).toList(),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.teal),
                    onPressed: () {
                      setState(() {
                        ingredientControllers.add(TextEditingController());
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text("Steps",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ...stepControllers.map((controller) {
                    int index = stepControllers.indexOf(controller);
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                decoration:
                                    const InputDecoration(labelText: "Step"),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle),
                              color: Colors.red,
                              onPressed: () {
                                setState(() {
                                  stepControllers.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10), // Extra távolság
                      ],
                    );
                  }).toList(),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.teal),
                    onPressed: () {
                      setState(() {
                        stepControllers.add(TextEditingController());
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Save Changes"),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _confirmDeleteRecipe() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Delete Recipe'),
          content: const Text('Are you sure you want to delete this recipe?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteRecipe();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRecipe() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_imageUrl != null) {
        try {
          final oldImageRef = FirebaseStorage.instance.refFromURL(_imageUrl!);
          await oldImageRef.delete();
        } catch (e) {
          print('Error deleting image from Storage: $e');
        }
      }

      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipeId)
          .delete();

      Navigator.of(context).pop();
    } catch (e) {
      _showError('Failed to delete recipe: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    prepTimeController.dispose();
    ingredientControllers.forEach((controller) => controller.dispose());
    stepControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }
}
