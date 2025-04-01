import 'package:flutter/material.dart';
import 'profile/profile_screen.dart'; // Már megvan
import 'workouts/categories/categories_for_workouts_screen.dart'; // Az edzések képernyője
import 'ai_chat/ai_chat_screen.dart'; // AI Chat képernyője
import 'recipes/recipes_screen.dart'; // Receptek képernyője

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  _BottomNavScreenState createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _currentIndex = 0;

  // Négy képernyő: Edzések, AI Chat, Receptek, Profil
  final List<Widget> _pages = [
    WorkoutsScreen(),
    const AIChatScreen(),
    RecipesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blueAccent, // Háttérszín
        selectedItemColor:
            Colors.lightBlueAccent, // Aktív ikonok világoskék színe
        unselectedItemColor: Colors.grey, // Inaktív ikonok színe
        currentIndex: _currentIndex,
        onTap: (int newIndex) {
          setState(() {
            _currentIndex = newIndex;
          });
        },
        items: const [
          BottomNavigationBarItem(
            label: 'Workouts',
            icon: Icon(Icons.fitness_center),
          ),
          BottomNavigationBarItem(
            label: 'FitBot',
            icon: Icon(Icons.chat),
          ),
          BottomNavigationBarItem(
            label: 'Recipes',
            icon: Icon(Icons.restaurant_menu),
          ),
          BottomNavigationBarItem(
            label: 'Profile',
            icon: Icon(Icons.person),
          ),
        ],
      ),
    );
  }
}
