import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '/pages/profile/profile_screen.dart';
import '/pages/workouts/categories/categories_for_workouts_screen.dart';
import '/pages/ai_chat/ai_chat_screen.dart';
import '/pages/recipes/recipes_screen.dart';

/// Ez a képernyő a FitWithUs alkalmazás alsó navigációs sávját és hozzá tartozó oldalváltást valósítja meg.
///
/// Vendég felhasználók és bejelentkezett felhasználók eltérő menüpontokat látnak:
/// - Vendégek: Workouts, Recipes, Profile
/// - Bejelentkezettek: Workouts, FitBot (AI chat), Recipes, Profile
///
/// A `FirebaseAuth.instance.currentUser` alapján állapítja meg, hogy vendég-e a felhasználó.
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

  /// Inicializálja az elérhető képernyőket és menüpontokat a felhasználó típusa alapján.
  /// A `FirebaseAuth.instance.currentUser.isAnonymous` alapján állapítja meg a vendég státuszt.
  ///
  /// Beállítja:
  /// - `_pages`: a képernyők listáját
  /// - `_items`: a `BottomNavigationBarItem` elemeket
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

  /// A képernyő megjelenítéséért felelős metódus.
  /// Megjeleníti:
  /// - az aktuálisan kiválasztott `_pages[_currentIndex]` képernyőt
  /// - az alsó navigációs sávot a `_items` elemekkel
  ///
  /// A kiválasztott menüpont színét a téma világos/sötét módja alapján állítja be.
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
