import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Próbáljuk betölteni Firestore-ból
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data != null && data.containsKey('isDarkMode')) {
        _isDarkMode = data['isDarkMode'] as bool;
        await prefs.setBool('isDarkMode', _isDarkMode); // lokális mentés is
      } else {
        // nincs ilyen mező, betöltjük SharedPreferences-ből fallbackként
        _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      }
    } else {
      // ha nem bejelentkezett user, akkor csak lokális
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    }

    notifyListeners();
  }

  Future<void> toggleTheme(bool isOn) async {
    _isDarkMode = isOn;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);

// Firestore mentés (ha van bejelentkezett felhasználó)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userRef.set({'isDarkMode': _isDarkMode}, SetOptions(merge: true));
    }
  }
}
