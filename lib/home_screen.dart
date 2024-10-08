import 'package:flutter/material.dart';
import 'profile_screen.dart'; // Már megvan
import 'workouts_screen.dart'; // Az edzések képernyője
import 'ai_chat_screen.dart'; // AI Chat képernyője
import 'recipes_screen.dart'; // Receptek képernyője

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
            label: 'AI Chat',
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
