import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditWorkoutScreen extends StatefulWidget {
  final String workoutId;
  final String initialTitle;
  final String initialDescription;
  final List<String> initialSteps;

  const EditWorkoutScreen({
    super.key,
    required this.workoutId,
    required this.initialTitle,
    required this.initialDescription,
    required this.initialSteps,
  });

  @override
  _EditWorkoutScreenState createState() => _EditWorkoutScreenState();
}

class _EditWorkoutScreenState extends State<EditWorkoutScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  List<TextEditingController> _stepsControllers = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descriptionController =
        TextEditingController(text: widget.initialDescription);

    // Lépésekhez külön TextEditingController-ek létrehozása
    for (String step in widget.initialSteps) {
      _stepsControllers.add(TextEditingController(text: step));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var controller in _stepsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Edzés adatainak mentése Firestore-ba
  Future<void> _saveWorkout() async {
    String newTitle = _titleController.text.trim();
    String newDescription = _descriptionController.text.trim();
    List<String> newSteps =
        _stepsControllers.map((controller) => controller.text.trim()).toList();

    if (newTitle.isEmpty ||
        newDescription.isEmpty ||
        newSteps.any((step) => step.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('workouts')
          .doc(widget.workoutId)
          .update({
        'title': newTitle,
        'description': newDescription,
        'steps': newSteps,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout updated successfully')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating workout')),
      );
    }
  }

  // Edzés törlése Firestore-ból
  Future<void> _deleteWorkout() async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout'),
        content: const Text(
            'Are you sure you want to delete this workout? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete) {
      try {
        await FirebaseFirestore.instance
            .collection('workouts')
            .doc(widget.workoutId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout deleted successfully')),
        );
        Navigator.of(context).pop(); // Visszatérés az előző képernyőre
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting workout')),
        );
      }
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
        title: const Text('Edit Workout'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              TextButton.icon(
                onPressed: _addStep,
                icon: const Icon(Icons.add),
                label: const Text('Add Step'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveWorkout,
                child: const Text('Save Changes'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _deleteWorkout,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete Workout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
