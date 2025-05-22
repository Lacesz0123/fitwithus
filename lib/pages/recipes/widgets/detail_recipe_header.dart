import 'package:flutter/material.dart';

/// Egy recept fejlécének megjelenítésére szolgáló stateless widget.
///
/// A `RecipeHeader` widget a recept címét, leírását, elkészítési idejét és opcionálisan
/// kalóriatartalmát jeleníti meg. Emellett megjelenít egy csillag ikont is, amely
/// lehetőséget biztosít a recept kedvencként való megjelölésére vagy annak eltávolítására.
///
/// ---
///
/// ### Konstruktor paraméterek:
/// - [name] – A recept neve (kötelező).
/// - [prepTime] – Az elkészítési idő percekben (kötelező).
/// - [description] – A recept rövid leírása (kötelező).
/// - [calories] – A recept kalóriatartalma (opcionális, ha van értelmezve).
/// - [isFavorite] – Jelzi, hogy a recept kedvencként van-e megjelölve.
/// - [onToggleFavorite] – A csillag ikon megnyomására hívott visszahívási függvény.
/// - [showFavoriteButton] – Ha `true`, akkor megjelenik a kedvenc ikon.
///
/// ---
///
/// ### Funkciók:
/// - Megjeleníti a recept címét nagy betűkkel, kiemelve a témának megfelelő színnel.
/// - Feltételesen jeleníti meg a kedvenc (csillag) ikont.
/// - Feltételesen jeleníti meg a kalóriainformációkat.
/// - Sötét és világos módhoz illeszkedik.
class RecipeHeader extends StatelessWidget {
  final String name;
  final int prepTime;
  final String description;
  final int? calories;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final bool showFavoriteButton;

  const RecipeHeader({
    super.key,
    required this.name,
    required this.prepTime,
    required this.description,
    required this.calories,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.showFavoriteButton,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.blueAccent,
                ),
              ),
            ),
            if (showFavoriteButton)
              GestureDetector(
                onTap: onToggleFavorite,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: isFavorite
                        ? (isDark
                            ? Colors.grey.shade700.withOpacity(0.4)
                            : Colors.yellow.shade100)
                        : (isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200),
                    shape: BoxShape.circle,
                    boxShadow: [],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite
                        ? (isDark ? Colors.orange.shade200 : Colors.orange)
                        : (isDark ? Colors.grey.shade400 : Colors.grey),
                    size: 30,
                  ),
                ),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.access_time,
                color: isDark ? Colors.grey[400] : Colors.grey),
            const SizedBox(width: 8),
            Text(
              "Preparation Time: $prepTime minutes",
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[300] : Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        if (calories != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.local_fire_department,
                  color: isDark ? Colors.red.shade300 : Colors.red),
              const SizedBox(width: 8),
              Text(
                "Calories: $calories kcal",
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[300] : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
