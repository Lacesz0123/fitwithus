import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '/utils/custom_snackbar.dart';

/// Fő widget, amely megjeleníti a napi vízfogyasztási adatokat, célértéket, egy pohárvizet reprezentáló grafikát,
/// valamint input mezőt és gombokat az interakcióhoz.
///
/// Adatok:
/// - `_dailyWaterIntake`: az aktuálisan elfogyasztott vízmennyiség (ml).
/// - `_dailyGoal`: automatikusan kiszámolt célérték a testsúly, magasság és nem alapján.
///
/// Firestore:
/// - `users/{uid}.dailyWaterIntake` mező kezelése.
/// - Testsúly/magasság/nem alapján célérték újrakalkulálás.
class WaterTrackerCard extends StatefulWidget {
  const WaterTrackerCard({super.key});

  @override
  State<WaterTrackerCard> createState() => _WaterTrackerCardState();
}

class _WaterTrackerCardState extends State<WaterTrackerCard> {
  int _dailyWaterIntake = 0;
  int _dailyGoal = 2000;
  final TextEditingController _inputController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadWaterDataAndGoal();
  }

  Future<void> _loadWaterDataAndGoal() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    final data = doc.data();

    if (data != null) {
      setState(() {
        _dailyWaterIntake = data['dailyWaterIntake'] ?? 0;
      });

      // Kalkuláljuk a víz szükségletet testsúly alapján
      final double weight = (data['weight'] as num?)?.toDouble() ?? 70.0;
      final double height = (data['height'] as num?)?.toDouble() ?? 170.0;
      final String gender = data['gender'] ?? 'Male';

      /// Formula: weight * 35 + height * 2
      /// - Férfiaknak +200 ml
      /// - Nőknek –100 ml
      double goal = weight * 35 + height * 2;
      if (gender == 'Male') {
        goal += 200;
      } else if (gender == 'Female') {
        goal -= 100;
      }

      setState(() {
        _dailyGoal = goal.round();
      });

      // Ha nincs water mező, inicializáljuk
      if (!data.containsKey('dailyWaterIntake')) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .set({'dailyWaterIntake': 0}, SetOptions(merge: true));
      }
    }
  }

  Future<void> _addWater() async {
    final inputText = _inputController.text.trim();

    if (inputText.isEmpty) {
      showCustomSnackBar(context, 'Please enter a value.', isError: true);
      return;
    }

    final input = int.tryParse(inputText);

    if (input == null || input <= 0) {
      showCustomSnackBar(
          context, 'Please enter a positive whole number (e.g. 250).',
          isError: true);
      return;
    }

    if (user != null) {
      setState(() {
        _dailyWaterIntake += input;
      });

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set(
        {'dailyWaterIntake': _dailyWaterIntake},
        SetOptions(merge: true),
      );

      _inputController.clear();
      showCustomSnackBar(context, 'Water added successfully');
    }
  }

  Future<void> _resetWaterIntake() async {
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({'dailyWaterIntake': 0}, SetOptions(merge: true));

      setState(() {
        _dailyWaterIntake = 0;
      });

      showCustomSnackBar(context, 'Water intake reset successfully');
    }
  }

  void _showResetDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Water Intake'),
        content: const Text(
            'Are you sure you want to reset your water intake for today?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? Theme.of(context).textTheme.bodyLarge?.color
                    : Colors.black,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetWaterIntake();
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dailyWaterIntake / _dailyGoal).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Water Intake',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Current: $_dailyWaterIntake / $_dailyGoal ml',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: WaterGlassIndicator(progress: progress),
                ),
                const SizedBox(height: 14),
                const SizedBox(height: 14),
                Column(
                  children: [
                    TextField(
                      controller: _inputController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        hintText: 'Add water (ml)',
                        hintStyle:
                            TextStyle(color: Theme.of(context).hintColor),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _addWater,
                          icon: const Icon(Icons.local_drink,
                              color: Colors.white),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.grey.shade700
                                : Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _showResetDialog,
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text('Reset'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Egy 60x120 pixeles grafikus widget, amely egy stilizált, függőleges poharat jelenít meg,
/// és vizuálisan mutatja a progress értéket (0.0–1.0).
///
/// - A `progress` a napi bevitt víz arányát jelzi a célhoz képest.
/// - `CustomPaint` használatával a `Canvas`-re rajzol.
/// - Árnyék, körvonal és vízkitöltés jelenik meg.
///
/// Használja a `_ModernGlassPainter` osztályt.
class WaterGlassIndicator extends StatelessWidget {
  final double progress;

  const WaterGlassIndicator({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 60,
        height: 120,
        child: CustomPaint(
          size: const Size(60, 120),
          painter: _ModernGlassPainter(
              progress, Theme.of(context).brightness == Brightness.dark),
        ));
  }
}

/// CustomPainter osztály, amely megrajzolja a vízpoharat és a benne lévő vízszintet.
///
/// - A pohár trapezoid alakú, fentről szélesebb.
/// - A víz szintje arányosan jelenik meg a progress érték alapján.
/// - Témafüggő színezést használ (világos/sötét).
///
/// Színezés:
/// - Sötét téma: világosabb szürke körvonal
/// - Világos téma: sötétebb kontúrvonal, halvány árnyékok
class _ModernGlassPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _ModernGlassPainter(this.progress, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double fillHeight = height * progress;

    // 🔷 Pohár formája – szélesebb felül, keskenyebb alul
    final Path glassPath = Path()
      ..moveTo(width * 0.1, 0)
      ..lineTo(width * 0.2, height)
      ..lineTo(width * 0.8, height)
      ..lineTo(width * 0.9, 0)
      ..close();

    // 🔷 Víz kitöltés – a pohár szélét követi
    final double leftX = width * 0.1 + (width * 0.1 * (1 - progress));
    final double rightX = width * 0.9 - (width * 0.1 * (1 - progress));
    final double topY = height - fillHeight;

    final Path fillPath = Path()
      ..moveTo(leftX, topY)
      ..lineTo(width * 0.2, height)
      ..lineTo(width * 0.8, height)
      ..lineTo(rightX, topY)
      ..close();

    // Árnyék
    canvas.drawShadow(glassPath, Colors.black.withOpacity(0.2), 4, false);

    // Pohár körvonal
    final Paint borderPaint = Paint()
      ..color = isDark ? Colors.grey.shade400 : Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Víz kitöltő festék
    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.blueAccent.withOpacity(0.6),
          Colors.lightBlueAccent.withOpacity(0.3),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(glassPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ModernGlassPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
