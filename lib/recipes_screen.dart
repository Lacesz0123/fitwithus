import 'package:flutter/material.dart';

class RecipesScreen extends StatelessWidget {
  RecipesScreen({super.key});

  // Alap receptlista
  final List<String> recipes = [
    "Quinoa Salad",
    "Avocado Toast",
    "Grilled Chicken with Veggies",
    "Smoothie Bowl",
    "Oatmeal with Berries",
    "Grilled Salmon",
    "Vegetable Stir Fry",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Healthy Recipes")),
      body: ListView.builder(
        itemCount: recipes.length,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 4.0, // Emelkedés a vizuális kiemeléshez
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10.0),
                title: Text(
                  recipes[index],
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  // Recept részleteinek megnyitása (opcionális későbbi funkció)
                  print('Selected recipe: ${recipes[index]}');
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
