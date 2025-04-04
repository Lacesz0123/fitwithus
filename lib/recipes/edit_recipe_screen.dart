import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/edit_recipe_header.dart';
import 'widgets/edit_recipe_ingredients_checklist.dart';
import 'widgets/edit_recipe_steps.dart';
import '../../utils/validators.dart';

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
        .then((document) {
      if (document.exists) {
        final data = document.data() as Map<String, dynamic>;
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
    final data = doc.data() as Map<String, dynamic>;

    setState(() {
      nameController.text = data['name'];
      descriptionController.text = data['description'];
      prepTimeController.text = data['prepTime'].toString();
      _imageUrl = data['imageUrl'];
      caloriesController.text = data['calories']?.toString() ?? '';
      ingredientControllers = (data['ingredients'] as List<dynamic>)
          .map((i) => TextEditingController(text: i))
          .toList();
      stepControllers = (data['steps'] as List<dynamic>)
          .map((s) => TextEditingController(text: s))
          .toList();
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      final bytes = await file.length();
      if (bytes > 5 * 1024 * 1024) {
        _showError('Image size cannot exceed 5MB.');
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
        final oldRef = FirebaseStorage.instance.refFromURL(_imageUrl!);
        await oldRef.delete();
      } catch (_) {}
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

    final validationMessage = Validators.validateEditedRecipe(
      name: nameController.text,
      description: descriptionController.text,
      prepTime: prepTimeController.text,
      calories: caloriesController.text,
      ingredients: ingredientControllers,
      steps: stepControllers,
    );

    if (validationMessage != null) {
      _showError(validationMessage);
      return;
    }

    try {
      final imageUrl = await _uploadImage();

      final updatedIngredients = ingredientControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final updatedSteps = stepControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipeId)
          .update({
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'prepTime': int.parse(prepTimeController.text.trim()),
        'calories': int.parse(caloriesController.text.trim()),
        'ingredients': updatedIngredients,
        'steps': updatedSteps,
        'imageUrl': imageUrl ?? _imageUrl,
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _confirmDeleteRecipe() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Recipe'),
        content: const Text('Are you sure you want to delete this recipe?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRecipe();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecipe() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_imageUrl != null) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(_imageUrl!);
          await ref.delete();
        } catch (_) {}
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
    caloriesController.dispose();
    prepTimeController.dispose();
    ingredientControllers.forEach((c) => c.dispose());
    stepControllers.forEach((c) => c.dispose());
    super.dispose();
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EditRecipeHeader(
                    nameController: nameController,
                    descriptionController: descriptionController,
                    caloriesController: caloriesController,
                    prepTimeController: prepTimeController,
                    imageUrl: _imageUrl,
                    selectedImage: _selectedImage,
                    onImagePick: _pickImage,
                  ),
                  const SizedBox(height: 20),
                  EditRecipeIngredients(
                    controllers: ingredientControllers,
                    onChanged: () => setState(() {}),
                    onAddIngredient: () {
                      setState(() {
                        ingredientControllers.add(TextEditingController());
                      });
                    },
                    onRemoveIngredient: (index) {
                      setState(() {
                        ingredientControllers.removeAt(index);
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  EditRecipeSteps(
                    controllers: stepControllers,
                    onChanged: () => setState(() {}),
                    onAddStep: () {
                      setState(() {
                        stepControllers.add(TextEditingController());
                      });
                    },
                    onRemoveStep: (index) {
                      setState(() {
                        stepControllers.removeAt(index);
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Save Changes"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
