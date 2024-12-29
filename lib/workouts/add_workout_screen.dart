import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddWorkoutScreen extends StatefulWidget {
  final String category;

  const AddWorkoutScreen({super.key, required this.category});

  @override
  _AddWorkoutScreenState createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<TextEditingController> _stepsControllers = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var controller in _stepsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Új edzés hozzáadása
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
        await FirebaseFirestore.instance.collection('workouts').add({
          'title': title,
          'description': description,
          'steps': steps,
          'category': widget.category,
        });

        Navigator.of(context).pop(); // Visszatérés az előző képernyőre
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout added successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error adding workout')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
    }
  }

  // Új lépés hozzáadása
  void _addStep() {
    setState(() {
      _stepsControllers.add(TextEditingController());
    });
  }

  // Lépés eltávolítása
  void _removeStep(int index) {
    setState(() {
      _stepsControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Workout'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.tealAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Workout Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Workout Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Steps',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _stepsControllers.length,
                itemBuilder: (context, index) {
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _stepsControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Step ${index + 1}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeStep(index),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _addStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Add Step'),
              ),
              const SizedBox(
                  height: 30), // Extra távolság biztosítása a gomb fölött
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width *
                      0.8, // A gomb szélessége a képernyő 80%-a
                  child: ElevatedButton(
                    onPressed: _addWorkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Add Workout',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
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
