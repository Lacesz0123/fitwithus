// lib/profile/statistics/widgets/workout_progress_card.dart

import 'package:flutter/material.dart';

class WorkoutProgressCard extends StatelessWidget {
  final int completedWorkouts;

  const WorkoutProgressCard({super.key, required this.completedWorkouts});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workout Progress Goals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 20),
            _buildProgressBar(context, '10 Workouts Goal', completedWorkouts,
                10, Colors.green),
            const SizedBox(height: 10),
            _buildProgressBar(context, '50 Workouts Goal', completedWorkouts,
                50, Colors.orange),
            const SizedBox(height: 10),
            _buildProgressBar(context, '100 Workouts Goal', completedWorkouts,
                100, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    String label,
    int completed,
    int goal,
    Color color,
  ) {
    double progress = (completed / goal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        Stack(
          children: [
            Container(
              width: double.infinity,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.9 * progress,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          '${(progress * 100).toStringAsFixed(1)}% ($completed/$goal)',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }
}
