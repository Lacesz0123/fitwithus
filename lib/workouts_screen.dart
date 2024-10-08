import 'package:flutter/material.dart';
import 'meditation_workouts_screen.dart'; // Importáljuk az új képernyőt

class WorkoutsScreen extends StatelessWidget {
  WorkoutsScreen({super.key});

  // Ideiglenes edzéskategóriák listája
  final List<Map<String, String>> categories = [
    {"title": "HOT & NEW", "image": "assets/hot_new.jpg"},
    {"title": "Meditation", "image": "assets/meditation.jpg"},
    {"title": "Mobility", "image": "assets/mobility.jpg"},
    {"title": "Rehab", "image": "assets/rehab.jpg"},
    {"title": "Yoga", "image": "assets/yoga.jpg"},
    {"title": "Low Impact", "image": "assets/low_impact.jpg"},
    {"title": "Stretch", "image": "assets/stretch.jpg"},
    {"title": "Strength", "image": "assets/strength.jpg"},
    {"title": "HIIT", "image": "assets/hiit.jpg"},
    {"title": "Cardio", "image": "assets/cardio.jpg"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Categories'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 oszlopos rács
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            childAspectRatio: 1.0, // A rács négyzetszerű elrendezése
          ),
          itemCount: categories.length,
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTap: () {
                // Navigálás a meditációs gyakorlatok listájára
                if (categories[index]['title'] == 'Meditation') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MeditationWorkoutsScreen(),
                    ),
                  );
                } else {
                  print("Selected category: ${categories[index]['title']}");
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                        categories[index]['image']!), // A kép elérési útja
                    fit: BoxFit.cover, // A kép kitölti a konténert
                  ),
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    color: Colors.black54, // Félig átlátszó fekete háttér
                    child: Text(
                      categories[index]['title']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
