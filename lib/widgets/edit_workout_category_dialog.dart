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

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Category updated successfully')),
    );
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

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Category and workouts deleted successfully')),
      );
    } catch (e) {
      print('Error deleting category and workouts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting category and workouts')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      title: Row(
        children: const [
          Icon(Icons.edit, color: Colors.blueAccent),
          SizedBox(width: 10),
          Text('Edit Category', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            maxLength: 18,
            decoration: InputDecoration(
              labelText: 'Category Title',
              counterText: '',
              labelStyle: const TextStyle(color: Colors.blueAccent),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Colors.blueAccent, width: 2),
              ),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image, color: Colors.white),
            label: const Text('Select New Image'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
      actions: [
        Column(
          children: [
            ElevatedButton(
              onPressed: _updateCategory,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Update'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _deleteCategory,
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ],
    );
  }
}
