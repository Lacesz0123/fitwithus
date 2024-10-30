import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditRecipeScreen extends StatefulWidget {
  final String recipeId;

  const EditRecipeScreen({Key? key, required this.recipeId}) : super(key: key);

  @override
  _EditRecipeScreenState createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController prepTimeController = TextEditingController();
  List<TextEditingController> ingredientControllers = [];
  List<TextEditingController> stepControllers = [];
  File? _selectedImage;
  String? _imageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecipeData();
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
    });
  }

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
    if (_selectedImage == null) return _imageUrl;

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
      final imageUrl = await _uploadImage();
      List<String> ingredients = ingredientControllers
          .map((controller) => controller.text)
          .where((text) => text.isNotEmpty)
          .toList();
      List<String> steps = stepControllers
          .map((controller) => controller.text)
          .where((text) => text.isNotEmpty)
          .toList();

      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipeId)
          .update({
        'name': nameController.text,
        'description': descriptionController.text,
        'prepTime': int.parse(prepTimeController.text),
        'ingredients': ingredients,
        'steps': steps,
        'imageUrl': imageUrl ?? _imageUrl,
      });

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save changes: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Recipe")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Recipe Name"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: "Description"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: prepTimeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: "Preparation Time (minutes)"),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _selectedImage != null
                          ? Image.file(
                              _selectedImage!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            )
                          : (_imageUrl != null
                              ? Image.network(
                                  _imageUrl!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : const Text("No image selected")),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _pickImage,
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
                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration:
                                const InputDecoration(labelText: "Ingredient"),
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
                    );
                  }).toList(),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    color: Colors.green,
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
                    return Row(
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
                    );
                  }).toList(),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    color: Colors.green,
                    onPressed: () {
                      setState(() {
                        stepControllers.add(TextEditingController());
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveChanges,
                    child: const Text("Save Changes"),
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
    ingredientControllers.forEach((controller) => controller.dispose());
    stepControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }
}
