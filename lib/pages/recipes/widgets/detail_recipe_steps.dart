import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A receptlépések listájának megjelenítésére szolgáló widget, választható kipipálási lehetőséggel.
///
/// A `RecipeSteps` widget egy adott recept lépéseit jeleníti meg ellenőrzőlistaként (checkboxokkal),
/// ahol a felhasználó megjelölheti, hogy melyik lépéssel végzett már. A kipipált állapotokat a
/// `SharedPreferences`-ben tárolja a `recipeId` alapján, így a kijelölések megmaradnak újraindítás után is.
///
/// ---
///
/// ### Paraméterek:
/// - [steps]: A recept lépéseit tartalmazó szöveges lista.
/// - [recipeId]: Az adott recept egyedi azonosítója, amely alapján a tárolás történik.
///
/// ---
///
/// ### Funkciók:
/// - Automatikusan betölti az adott recept korábban kijelölt lépéseit a `SharedPreferences`-ből.
/// - A felhasználó jelölheti a kész lépéseket, a változások azonnal mentésre kerülnek.
/// - A kipipált elemek vizuálisan áthúzásra kerülnek.
/// - Támogatja a sötét és világos módot, valamint az új lépések dinamikus betöltését is.
class RecipeSteps extends StatefulWidget {
  final List<String> steps;
  final String recipeId;

  const RecipeSteps({super.key, required this.steps, required this.recipeId});

  @override
  State<RecipeSteps> createState() => _RecipeStepsState();
}

class _RecipeStepsState extends State<RecipeSteps> {
  List<bool> _checkedSteps = [];

  @override
  void initState() {
    super.initState();
    if (widget.steps.isNotEmpty) {
      _initializeSteps();
    }
  }

  @override
  void didUpdateWidget(covariant RecipeSteps oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.steps != widget.steps && widget.steps.isNotEmpty) {
      _initializeSteps();
    }
  }

  Future<void> _initializeSteps() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? saved =
        prefs.getStringList('checkedRecipeSteps_${widget.recipeId}');

    if (saved != null && saved.length == widget.steps.length) {
      _checkedSteps = saved.map((e) => e == 'true').toList();
    } else {
      _checkedSteps = List<bool>.filled(widget.steps.length, false);
      await prefs.setStringList(
        'checkedRecipeSteps_${widget.recipeId}',
        _checkedSteps.map((e) => e.toString()).toList(),
      );
    }

    setState(() {});
  }

  Future<void> _saveCheckedSteps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'checkedRecipeSteps_${widget.recipeId}',
      _checkedSteps.map((e) => e.toString()).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.steps.isEmpty || _checkedSteps.length != widget.steps.length) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Steps:",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey.shade300 : Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 8),
        ...widget.steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _checkedSteps[index],
                  onChanged: (value) {
                    setState(() {
                      _checkedSteps[index] = value ?? false;
                    });
                    _saveCheckedSteps();
                  },
                  fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                    if (_checkedSteps[index]) {
                      return isDark ? Colors.grey : Colors.blueAccent;
                    }
                    return isDark ? Colors.black : Colors.white;
                  }),
                  side: MaterialStateBorderSide.resolveWith((states) {
                    if (!_checkedSteps[index]) {
                      return BorderSide(
                        color: isDark ? Colors.white : Colors.black,
                        width: 2,
                      );
                    }
                    return BorderSide.none;
                  }),
                  checkColor: Colors.white,
                ),
                Expanded(
                  child: Text(
                    "${index + 1}. $step",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                      decoration: _checkedSteps[index]
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
