import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyWorkoutsScreen extends StatefulWidget {
  const MyWorkoutsScreen({super.key});

  @override
  State<MyWorkoutsScreen> createState() => _MyWorkoutsScreenState();
}

class _MyWorkoutsScreenState extends State<MyWorkoutsScreen> {
  final userId = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _addWorkout() async {
    final titleController = TextEditingController();
    final stepsController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("New Workout"),
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Workout Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: stepsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Steps (separate by new line)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Add"),
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('my_workouts')
                      .add({
                    'title': titleController.text.trim(),
                    'steps': stepsController.text.trim().split('\n'),
                    'createdAt': Timestamp.now(),
                    'favorite': false,
                  });
                }
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleFavorite(String id, bool current) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('my_workouts')
        .doc(id)
        .update({'favorite': !current});
  }

  Future<void> _deleteWorkout(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Workout"),
        content: const Text("Are you sure you want to delete this workout?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('my_workouts')
          .doc(id)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Workouts"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addWorkout,
          )
        ],
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
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('my_workouts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final workouts = snapshot.data!.docs;

          if (workouts.isEmpty) {
            return const Center(child: Text("No workouts yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final data = workouts[index].data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Untitled';
              final steps = List<String>.from(data['steps'] ?? []);
              final favorite = data['favorite'] == true;

              return Card(
                color: cardColor,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                          ),
                          IconButton(
                            icon: Icon(
                              favorite ? Icons.star : Icons.star_border,
                              color: favorite
                                  ? (isDark
                                      ? Colors.orange.shade300
                                      : Colors.orange)
                                  : Colors.grey,
                            ),
                            onPressed: () =>
                                _toggleFavorite(workouts[index].id, favorite),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteWorkout(workouts[index].id),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...steps
                          .asMap()
                          .entries
                          .map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '${e.key + 1}. ${e.value}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ))
                          .toList(),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
