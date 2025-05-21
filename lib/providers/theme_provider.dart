import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A `ThemeProvider` osztály a világos/sötét mód beállítását kezeli.
///
/// Az aktuális téma információját a következő forrásokból olvassa be:
/// 1. Bejelentkezett felhasználó esetén: Firestore `users/{uid}/isDarkMode`
/// 2. Lokálisan: `SharedPreferences`
///
/// A változások automatikusan érvénybe lépnek a `notifyListeners()` hívással.
class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  /// Lekérdezi, hogy sötét módban van-e az alkalmazás.
  bool get isDarkMode => _isDarkMode;

  /// Konstruktor: betölti a témabeállítást Firestore-ból vagy SharedPreferences-ből.
  ThemeProvider() {
    _loadTheme();
  }

  /// A témabeállítás betöltése.
  ///
  /// Bejelentkezett felhasználó esetén először a Firestore-ból olvasunk,
  /// ha nincs adat, vagy nincs bejelentkezve, akkor a lokális `SharedPreferences`-ből.
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

  /// A témaváltás logikája. Frissíti az állapotot és menti az új értéket.
  ///
  /// - Frissíti a belső `_isDarkMode` állapotot
  /// - Értesíti a UI-t (`notifyListeners`)
  /// - Elmenti a beállítást a `SharedPreferences`-be
  /// - Bejelentkezett felhasználó esetén elmenti a Firestore `users/{uid}` dokumentumba is
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
