import 'package:flutter/material.dart';

/// A recept hozzávalóinak szerkesztésére szolgáló widget.
///
/// Az `EditRecipeIngredients` egy lista formájában jeleníti meg a szerkeszthető
/// hozzávalókat, ahol minden egyes hozzávalóhoz tartozik egy `TextField`.
/// Lehetőség van új hozzávalók hozzáadására és meglévők törlésére.
///
/// Ez a komponens általában az `EditRecipeScreen` egyik alkomponense.
///
/// ---
///
/// ### Paraméterek:
/// - [controllers]: A hozzávalók `TextEditingController` példányainak listája.
/// - [onChanged]: Hívódik, ha bármelyik hozzávaló szövege megváltozik.
/// - [onAddIngredient]: Új hozzávaló hozzáadását kezdeményezi.
/// - [onRemoveIngredient]: Meglévő hozzávaló eltávolítása adott index alapján.
///
/// ---
///
/// ### Megjelenítés:
/// - Minden hozzávalóhoz tartozik egy `TextField`, amely címkéje: `"Ingredient"`
/// - A sor végén megjelenik egy piros `remove_circle` ikon a törléshez.
/// - Az új hozzávaló hozzáadása `OutlinedButton.icon` gombbal történik.
class EditRecipeIngredients extends StatelessWidget {
  final List<TextEditingController> controllers;
  final VoidCallback onChanged;
  final VoidCallback onAddIngredient;
  final Function(int) onRemoveIngredient;

  const EditRecipeIngredients({
    Key? key,
    required this.controllers,
    required this.onChanged,
    required this.onAddIngredient,
    required this.onRemoveIngredient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.grey.shade300 : Colors.blueAccent;
    final fillColor = isDark ? Colors.grey.shade800 : Colors.grey[100];
    final textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ingredients",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controllers.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controllers[index],
                      onChanged: (_) => onChanged(),
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: "Ingredient",
                        labelStyle: TextStyle(color: textColor),
                        filled: true,
                        fillColor: fillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.remove_circle,
                        color: Colors.redAccent),
                    onPressed: () => onRemoveIngredient(index),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Center(
          child: OutlinedButton.icon(
            onPressed: onAddIngredient,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Add Ingredient"),
            style: OutlinedButton.styleFrom(
              backgroundColor:
                  isDark ? Colors.grey.shade700 : Colors.blueAccent,
              foregroundColor: Colors.white,
              side: BorderSide(color: primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
