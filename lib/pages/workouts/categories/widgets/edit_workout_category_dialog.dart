import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/../utils/custom_snackbar.dart';

/// Egy dialógus ablak, amely lehetővé teszi egy meglévő edzéskategória szerkesztését vagy törlését.
///
/// A felhasználó módosíthatja:
/// - a kategória címét,
/// - a hozzárendelt képet.
///
/// A frissítés a Firestore `categories` kollekcióját módosítja.
/// Ha a cím megváltozik, az adott kategóriához tartozó `workouts` dokumentumokban is frissül a mező.
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

  /// Inicializálja a szövegmezőt az aktuális címmel.
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.currentTitle);
  }

  /// Képkiválasztó megnyitása galériából, majd előnézet és Snackbar visszajelzés.
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
      showCustomSnackBar(context, 'Image selected');
    }
  }

  /// Frissíti a kategóriát a Firestore-ban:
  /// - Ha új képet választott, feltölti a Firebase Storage-ba
  /// - Frissíti a címmezőket és a képet
  /// - Ha a cím változott, frissíti az összes kapcsolódó workout kategóriamezőjét is
  Future<void> _updateCategory() async {
    final newTitle = _titleController.text.trim();
    final oldTitle = widget.currentTitle;

    if (newTitle.isEmpty || newTitle.length > 18) {
      showCustomSnackBar(
        context,
        'Please enter a title (max 18 characters)',
        isError: true,
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
          .child('$newTitle.jpg');

      await storageRef.putFile(File(_pickedImage!.path));
      imageUrl = await storageRef.getDownloadURL();
    }

    // 1. Kategória frissítése
    await FirebaseFirestore.instance
        .collection('categories')
        .doc(widget.docId)
        .update({
      'title': newTitle,
      'title_lower': newTitle.toLowerCase(),
      'image': imageUrl,
    });

    // 2. Edzések frissítése, ha megváltozott a név
    if (newTitle != oldTitle) {
      final workoutsQuery = await FirebaseFirestore.instance
          .collection('workouts')
          .where('category', isEqualTo: oldTitle)
          .get();

      for (final doc in workoutsQuery.docs) {
        await doc.reference.update({'category': newTitle});
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
      showCustomSnackBar(context, 'Category updated successfully');
    }
  }

  /// Teljes kategóriatörlés:
  /// - Minden ehhez tartozó `workout` törlése
  /// - A kategória törlése a `categories` kollekcióból
  /// - A kapcsolódó kép törlése Firebase Storage-ból
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
        showCustomSnackBar(
            context, 'Category and workouts deleted successfully');
      }
    } catch (e) {
      print('Error deleting category and workouts: $e');
      showCustomSnackBar(
        context,
        'Error deleting category and workouts',
        isError: true,
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
              Row(
                children: [
                  Icon(
                    Icons.edit_outlined,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade300
                        : Colors.blueAccent,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Edit Category',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade300
                          : Colors.blueAccent,
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
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.grey[100],
                  prefixIcon: Icon(
                    Icons.title,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade300
                        : Colors.blueAccent,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade300
                          : Colors.blueAccent,
                      width: 2,
                    ),
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800.withOpacity(0.4)
                        : Colors.blueAccent.withOpacity(0.05),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade300.withOpacity(0.4)
                          : Colors.blueAccent.withOpacity(0.4),
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
                      icon: const Icon(
                        Icons.save,
                        color: Colors.white, // ikon marad fehér
                      ),
                      label: const Text('Update'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade700
                                : Colors.blueAccent,
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
                      icon: const Icon(
                        Icons.delete_forever,
                        color: Colors.white, // <-- biztosan fehér lesz
                      ),
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
