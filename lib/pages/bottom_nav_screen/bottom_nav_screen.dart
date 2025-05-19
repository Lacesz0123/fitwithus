import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '/pages/profile/profile_screen.dart';
import '/pages/workouts/categories/categories_for_workouts_screen.dart';
import '/pages/ai_chat/ai_chat_screen.dart';
import '/pages/recipes/recipes_screen.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  _BottomNavScreenState createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _currentIndex = 0;

  late bool isGuest;
  late List<Widget> _pages;
  late List<BottomNavigationBarItem> _items;

  @override
  void initState() {
    super.initState();

    final currentUser = FirebaseAuth.instance.currentUser;
    isGuest = currentUser?.isAnonymous ?? false;

    if (isGuest) {
      _pages = [
        WorkoutsScreen(),
        RecipesScreen(),
        const ProfileScreen(),
      ];
      _items = const [
        BottomNavigationBarItem(
          label: 'Workouts',
          icon: Icon(Icons.fitness_center),
        ),
        BottomNavigationBarItem(
          label: 'Recipes',
          icon: Icon(Icons.restaurant_menu),
        ),
        BottomNavigationBarItem(
          label: 'Profile',
          icon: Icon(Icons.person),
        ),
      ];
    } else {
      _pages = [
        WorkoutsScreen(),
        const AIChatScreen(),
        RecipesScreen(),
        const ProfileScreen(),
      ];
      _items = const [
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
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (int newIndex) {
          setState(() {
            _currentIndex = newIndex;
          });
        },
        items: _items,
      ),
    );
  }
}
