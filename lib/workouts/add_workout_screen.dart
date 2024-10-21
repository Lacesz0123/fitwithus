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
  final TextEditingController _stepsController = TextEditingController();

  Future<void> _addWorkout() async {
    String title = _titleController.text.trim();
    String description = _descriptionController.text.trim();
    List<String> steps = _stepsController.text.trim().split('\n');

    if (title.isNotEmpty && description.isNotEmpty && steps.isNotEmpty) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Workout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Workout Title',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Workout Description',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _stepsController,
              decoration: const InputDecoration(
                labelText: 'Steps (one per line)',
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addWorkout,
              child: const Text('Add Workout'),
            ),
          ],
        ),
      ),
    );
  }
}
