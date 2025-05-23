import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../utils/custom_snackbar.dart';

/// Új edzés hozzáadására szolgáló képernyő egy adott kategóriába.
///
/// A felhasználó megadhatja az edzés címét, leírását, lépéseit, valamint opcionálisan
/// egy YouTube-videó URL-t is.
/// Az adatokat a Firestore `workouts` kollekciójába menti el.
class AddWorkoutScreen extends StatefulWidget {
  final String category;

  const AddWorkoutScreen({super.key, required this.category});

  @override
  _AddWorkoutScreenState createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  List<TextEditingController> _stepsControllers = [];

  /// Felszabadítja a szövegbeviteli vezérlőket, amikor a képernyő megsemmisül.
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    for (var controller in _stepsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Új edzés létrehozása és mentése a Firestore adatbázisba.
  ///
  /// Ellenőrzi, hogy minden kötelező mező ki van-e töltve.
  /// Hibák esetén SnackBar üzenetet jelenít meg.
  Future<void> _addWorkout() async {
    String title = _titleController.text.trim();
    String description = _descriptionController.text.trim();
    List<String> steps =
        _stepsControllers.map((controller) => controller.text.trim()).toList();

    if (title.isNotEmpty &&
        description.isNotEmpty &&
        steps.isNotEmpty &&
        steps.every((step) => step.isNotEmpty)) {
      try {
        final Map<String, dynamic> workoutData = {
          'title': title,
          'description': description,
          'steps': steps,
          'category': widget.category,
        };

        String videoUrl = _videoUrlController.text.trim();
        if (videoUrl.isNotEmpty) {
          workoutData['videoUrl'] = videoUrl;
        }

        await FirebaseFirestore.instance
            .collection('workouts')
            .add(workoutData);

        Navigator.of(context).pop();
        showCustomSnackBar(context, 'Workout added successfully');
      } catch (e) {
        showCustomSnackBar(context, 'Error adding workout', isError: true);
      }
    } else {
      showCustomSnackBar(context, 'Please fill in all fields', isError: true);
    }
  }

  /// Új lépés (TextField) hozzáadása az edzéshez.
  void _addStep() {
    setState(() {
      _stepsControllers.add(TextEditingController());
    });
  }

  /// Adott lépés eltávolítása az index alapján.
  void _removeStep(int index) {
    setState(() {
      _stepsControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.white : Colors.blueAccent;
    final buttonColor = isDark ? Colors.grey.shade700 : Colors.blueAccent;
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Workout'),
        backgroundColor: backgroundColor,
        flexibleSpace: !isDark
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Workout Title',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryColor)),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              style: TextStyle(color: primaryColor),
              decoration: InputDecoration(
                hintText: 'Enter workout title',
                hintStyle: TextStyle(color: primaryColor.withOpacity(0.5)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Description',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryColor)),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              style: TextStyle(color: primaryColor),
              decoration: InputDecoration(
                hintText: 'Enter workout description',
                hintStyle: TextStyle(color: primaryColor.withOpacity(0.5)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 28),
            Text('Steps',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryColor)),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _stepsControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _stepsControllers[index],
                          style: TextStyle(color: primaryColor),
                          decoration: InputDecoration(
                            labelText: 'Step ${index + 1}',
                            labelStyle: TextStyle(color: primaryColor),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.remove_circle,
                            color: Colors.redAccent),
                        onPressed: () => _removeStep(index),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Center(
              child: OutlinedButton.icon(
                onPressed: _addStep,
                icon: Icon(Icons.add, color: primaryColor),
                label: Text('Add Step', style: TextStyle(color: primaryColor)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text('Video URL (optional)',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryColor)),
            const SizedBox(height: 6),
            TextField(
              controller: _videoUrlController,
              style: TextStyle(color: primaryColor),
              decoration: InputDecoration(
                hintText: 'https://www.youtube.com/watch?v=...',
                hintStyle: TextStyle(color: primaryColor.withOpacity(0.5)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                onPressed: _addWorkout,
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text(
                  'Add Workout',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
