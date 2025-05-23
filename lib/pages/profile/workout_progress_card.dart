import 'package:flutter/material.dart';

/// Egy stateless widget, amely edzéscélok teljesítését mutatja a felhasználó számára.
///
/// Paraméterek:
/// - `completedWorkouts` – az eddig teljesített edzések száma.
///
/// Három szintű cél:
/// - 10 edzés (zöld sáv)
/// - 50 edzés (narancssárga sáv)
/// - 100 edzés (piros sáv)
///
/// Minden progress bar mellett megjelenik a cím és az aktuális/kitűzött érték.
class WorkoutProgressCard extends StatelessWidget {
  final int completedWorkouts;

  const WorkoutProgressCard({super.key, required this.completedWorkouts});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : Colors.blueAccent;
    final labelColor = isDark ? Colors.grey.shade300 : Colors.black87;
    final secondaryTextColor = isDark ? Colors.grey.shade500 : Colors.black54;
    final progressBackground =
        isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workout Progress Goals',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildProgressBar('10 Workouts Goal', completedWorkouts, 10,
              Colors.green, labelColor, secondaryTextColor, progressBackground),
          const SizedBox(height: 12),
          _buildProgressBar(
              '50 Workouts Goal',
              completedWorkouts,
              50,
              Colors.orange,
              labelColor,
              secondaryTextColor,
              progressBackground),
          const SizedBox(height: 12),
          _buildProgressBar(
              '100 Workouts Goal',
              completedWorkouts,
              100,
              Colors.redAccent,
              labelColor,
              secondaryTextColor,
              progressBackground),
        ],
      ),
    );
  }

  /// Egy adott célhoz tartozó progress bar és aláírás megjelenítéséért felelős.
  ///
  /// Paraméterek:
  /// - `label`: a cél elnevezése (pl. "10 Workouts Goal").
  /// - `completed`: eddig teljesített érték.
  /// - `goal`: célérték (pl. 10).
  /// - `color`: az adott sáv színe.
  /// - `labelColor`: cím színe.
  /// - `secondaryColor`: arány (`X/Y`) színe.
  /// - `backgroundColor`: progress bar háttérszíne.
  ///
  /// Megjelenítés:
  /// - Cím (`label`)
  /// - Progress sáv (`LinearProgressIndicator`)
  /// - Szöveges arány (`X / Y`)
  Widget _buildProgressBar(
    String label,
    int completed,
    int goal,
    Color color,
    Color labelColor,
    Color secondaryColor,
    Color backgroundColor,
  ) {
    final int displayValue = completed > goal ? goal : completed;
    final double progress = (completed / goal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: labelColor),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 14,
            backgroundColor: backgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$displayValue / $goal',
          style: TextStyle(fontSize: 13, color: secondaryColor),
        ),
      ],
    );
  }
}
