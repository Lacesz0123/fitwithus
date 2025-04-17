import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditCategoryDialog extends StatefulWidget {
  final String docId;
  final String currentTitle;
  final String currentImage;

  const EditCategoryDialog({
    super.key,
    required this.docId,
    required this.currentTitle,
    required this.currentImage,
  });

  @override
  State<EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<EditCategoryDialog> {
  late TextEditingController _titleController;
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.currentTitle);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image selected')),
      );
    }
  }

  Future<void> _updateCategory() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || title.length > 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a title (max 18 characters)')),
      );
      return;
    }

    String imageUrl = widget.currentImage;

    if (_pickedImage != null) {
      try {
        await FirebaseStorage.instance.refFromURL(widget.currentImage).delete();
      } catch (e) {
        print('Error deleting previous image from Storage: $e');
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('category_images/categoryImages')
          .child('$title.jpg');

      await storageRef.putFile(File(_pickedImage!.path));
      imageUrl = await storageRef.getDownloadURL();
    }

    await FirebaseFirestore.instance
        .collection('categories')
        .doc(widget.docId)
        .update({
      'title': title,
      'title_lower': title.toLowerCase(),
      'image': imageUrl,
    });

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category updated successfully')),
      );
    }
  }

  Future<void> _deleteCategory() async {
    try {
      final workouts = await FirebaseFirestore.instance
          .collection('workouts')
          .where('category', isEqualTo: widget.currentTitle)
          .get();

      for (final doc in workouts.docs) {
        await FirebaseFirestore.instance
            .collection('workouts')
            .doc(doc.id)
            .delete();
      }

      await FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.docId)
          .delete();

      if (widget.currentImage.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(widget.currentImage).delete();
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Category and workouts deleted successfully')),
        );
      }
    } catch (e) {
      print('Error deleting category and workouts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting category and workouts')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Edit Category',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                maxLength: 18,
                decoration: InputDecoration(
                  labelText: 'Category Title',
                  counterText: '',
                  filled: true,
                  fillColor: Colors.grey[100],
                  prefixIcon: const Icon(Icons.title, color: Colors.blueAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.05),
                    border: Border.all(
                      color: Colors.blueAccent.withOpacity(0.4),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _pickedImage != null
                        ? Image.file(
                            File(_pickedImage!.path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 150,
                          )
                        : Image.network(
                            widget.currentImage,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 150,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(child: Icon(Icons.broken_image)),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _updateCategory,
                      icon: const Icon(Icons.save),
                      label: const Text('Update'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _deleteCategory,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
