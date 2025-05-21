import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // csak a teszt konstruktorhoz

/// A `FirebaseAuthService` osztály különféle Firebase-alapú bejelentkezési
/// lehetőségeket biztosít (email, Google, anonim), valamint a felhasználói adatok
/// lekérését és kijelentkezést.
class FirebaseAuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  /// Alapértelmezett konstruktor, amely az alkalmazásban használatos.
  FirebaseAuthService()
      : _auth = FirebaseAuth.instance,
        _googleSignIn = GoogleSignIn();

  /// Teszteléshez használható konstruktor, ahol a FirebaseAuth és GoogleSignIn
  /// példányokat külsőleg lehet átadni (mockolható).
  @visibleForTesting
  FirebaseAuthService.test({
    required FirebaseAuth auth,
    required GoogleSignIn googleSignIn,
  })  : _auth = auth,
        _googleSignIn = googleSignIn;

  /// Bejelentkezés email és jelszó segítségével.
  ///
  /// Visszaad egy [UserCredential] példányt sikeres bejelentkezés esetén.
  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Visszaadja az aktuálisan bejelentkezett felhasználót,
  /// vagy `null`-t, ha nincs bejelentkezve senki.
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Kijelentkezteti a jelenlegi felhasználót.
  Future<void> signOut() {
    return _auth.signOut();
  }

  /// Anonim bejelentkezést hajt végre.
  ///
  /// Ez lehetővé teszi, hogy a felhasználók regisztráció nélkül kipróbálják az alkalmazást.
  Future<UserCredential> signInAnonymously() async {
    return await FirebaseAuth.instance.signInAnonymously();
  }

  /// Google-fiókkal való bejelentkezés.
  ///
  /// - Elindítja a Google bejelentkezést
  /// - Hitelesítő adatokat kér a Google-től
  /// - Bejelentkezteti a felhasználót a Firebase Authentication segítségével
  /// - Ha új felhasználó, akkor Firestore-ban létrehoz egy `users/{uid}` dokumentumot
  ///
  /// Visszatérési érték: a bejelentkezett felhasználó [UserCredential] példánya, vagy `null`.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'username': userCredential.user!.displayName ?? 'User',
            'email': userCredential.user!.email,
            'gender': 'Male',
            'weight': 70.0,
            'height': 170.0,
            'birthDate': Timestamp.fromDate(DateTime(1990, 1, 1)),
            'dailyCalories': 0,
            'completedWorkouts': 0,
            'profileImageUrl': null,
            'role': 'user',
          }, SetOptions(merge: true));
        }
      }

      return userCredential;
    } catch (e) {
      print('Google Sign-In error: $e');
      rethrow;
    }
  }
}
