import 'package:flutter/material.dart';

class MeditationWorkoutsScreen extends StatefulWidget {
  MeditationWorkoutsScreen({super.key});

  @override
  _MeditationWorkoutsScreenState createState() =>
      _MeditationWorkoutsScreenState();
}

class _MeditationWorkoutsScreenState extends State<MeditationWorkoutsScreen> {
  // Alap gyakorlatlista címekkel
  final List<String> workouts = [
    "One",
    "Two",
    "Three",
    "Four",
  ];

  // Kedvencek állapota (alapértelmezés szerint minden szürke, nem kedvenc)
  Map<String, bool> favorites = {
    "One": false,
    "Two": false,
    "Three": false,
    "Four": false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meditation Workouts'),
      ),
      body: ListView.builder(
        itemCount: workouts.length,
        itemBuilder: (BuildContext context, int index) {
          String workoutTitle = workouts[index];

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
                  workoutTitle,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    favorites[workoutTitle] == true
                        ? Icons.star
                        : Icons.star_border,
                    color: favorites[workoutTitle] == true
                        ? Colors.yellow
                        : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      favorites[workoutTitle] = !favorites[workoutTitle]!;
                    });
                  },
                ),
                onTap: () {
                  // Gyakorlat részleteinek megnyitása (opcionális későbbi funkció)
                  print('Selected workout: $workoutTitle');
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
