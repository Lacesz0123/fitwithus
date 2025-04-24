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
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
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
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting workout')),
        );
      }
    }
  }

  void _addStep() {
    setState(() {
      _stepsControllers.add(TextEditingController());
    });
  }

  void _removeStep(int index) {
    setState(() {
      _stepsControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color buttonColor = isDark ? Colors.white : Colors.blueAccent;
    final Color primaryColor =
        isDark ? Colors.grey.shade700 : Colors.blueAccent;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color backgroundColor =
        isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Workout'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        flexibleSpace: isDark
            ? Container(color: const Color(0xFF1E1E1E))
            : Container(
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
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteWorkout,
          ),
        ],
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
                    color: textColor)),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Enter workout title',
                fillColor: backgroundColor,
                filled: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            Text('Description',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter workout description',
                fillColor: backgroundColor,
                filled: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 28),
            Text('Steps',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
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
                          decoration: InputDecoration(
                            labelText: 'Step ${index + 1}',
                            fillColor: backgroundColor,
                            filled: true,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
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
                icon: Icon(Icons.add, color: buttonColor),
                label: Text('Add Step', style: TextStyle(color: buttonColor)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: buttonColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: _saveWorkout,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text('Save Changes',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
