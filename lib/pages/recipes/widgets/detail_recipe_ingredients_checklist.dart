import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Egy összetevőlista megjelenítésére és kezelésére szolgáló interaktív widget receptoldalon.
///
/// Az `IngredientChecklist` widget egy checkbox-listát jelenít meg a megadott összetevőkkel.
/// A felhasználó kijelölheti, mely összetevőket használta már fel. A bejelölt állapotok
/// lokálisan mentésre kerülnek a [SharedPreferences] segítségével a megadott [recipeId] alapján.
///
/// ---
///
/// ### Konstruktor paraméterek:
/// - [ingredientsStatus] – A recept összetevőit és azok kezdeti (true/false) bejelöltségi állapotát tartalmazó map.
/// - [recipeId] – Az adott recept azonosítója, amely alapján a mentés és betöltés történik.
///
/// ---
///
/// ### Funkciók:
/// - Betölti az előzőleg elmentett állapotokat, ha azok léteznek.
/// - Lehetővé teszi az összetevők bejelölését (checkbox).
/// - A kijelölés áthúzott szövegstílussal jelenik meg.
/// - Automatikusan elmenti a változtatásokat a [SharedPreferences]-be.
/// - Támogatja a világos és sötét témát is.
class IngredientChecklist extends StatefulWidget {
  final Map<String, bool> ingredientsStatus;
  final String recipeId;

  const IngredientChecklist({
    super.key,
    required this.ingredientsStatus,
    required this.recipeId,
  });

  @override
  State<IngredientChecklist> createState() => _IngredientChecklistState();
}

class _IngredientChecklistState extends State<IngredientChecklist> {
  late Map<String, bool> _localStatus;

  @override
  void initState() {
    super.initState();
    _initializeIngredients();
  }

  @override
  void didUpdateWidget(covariant IngredientChecklist oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ingredientsStatus != widget.ingredientsStatus &&
        widget.ingredientsStatus.isNotEmpty) {
      _initializeIngredients();
    }
  }

  Future<void> _initializeIngredients() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('checkedIngredients_${widget.recipeId}');

    if (saved != null && saved.length == widget.ingredientsStatus.length) {
      final ingredientKeys = widget.ingredientsStatus.keys.toList();
      _localStatus = {
        for (int i = 0; i < ingredientKeys.length; i++)
          ingredientKeys[i]: saved[i] == 'true'
      };
    } else {
      _localStatus = {...widget.ingredientsStatus};
      await _saveCheckedIngredients();
    }

    setState(() {});
  }

  Future<void> _saveCheckedIngredients() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'checkedIngredients_${widget.recipeId}',
      _localStatus.values.map((e) => e.toString()).toList(),
    );
  }

  void _toggleIngredient(String ingredient) {
    setState(() {
      _localStatus[ingredient] = !(_localStatus[ingredient] ?? false);
    });
    _saveCheckedIngredients();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_localStatus.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ingredients:",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey.shade300 : Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 8),
        ..._localStatus.keys.map((ingredient) {
          final isChecked = _localStatus[ingredient] ?? false;

          return CheckboxListTile(
            title: Text(
              ingredient,
              style: TextStyle(
                fontSize: 16,
                color: isChecked
                    ? (isDark ? Colors.grey.shade600 : Colors.grey)
                    : (isDark ? Colors.white : Colors.black),
                decoration: isChecked
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
            value: isChecked,
            onChanged: (_) => _toggleIngredient(ingredient),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: isDark ? Colors.grey.shade400 : Colors.blueAccent,
            checkColor: Colors.white,
          );
        }).toList(),
      ],
    );
  }
}
