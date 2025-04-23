import 'package:flutter/material.dart';

class WorkoutProgressCard extends StatelessWidget {
  final int completedWorkouts;

  const WorkoutProgressCard({super.key, required this.completedWorkouts});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Workout Progress Goals',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 12),
          _buildProgressBar(
              '10 Workouts Goal', completedWorkouts, 10, Colors.green),
          const SizedBox(height: 12),
          _buildProgressBar(
              '50 Workouts Goal', completedWorkouts, 50, Colors.orange),
          const SizedBox(height: 12),
          _buildProgressBar(
              '100 Workouts Goal', completedWorkouts, 100, Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int completed, int goal, Color color) {
    final int displayValue = completed > goal ? goal : completed;
    final double progress = (completed / goal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 14,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$displayValue / $goal',
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
      ],
    );
  }
}
