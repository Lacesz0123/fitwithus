// lib/services/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  Future<UserCredential> signInAnonymously() async {
    return await FirebaseAuth.instance.signInAnonymously();
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Google bejelentkezés indítása
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // A felhasználó megszakította a bejelentkezést
        return null;
      }

      // Google hitelesítési adatok lekérése
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase hitelesítési token létrehozása
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Bejelentkezés a Firebase-ba
      final userCredential = await _auth.signInWithCredential(credential);

      // Ellenőrizzük, hogy a felhasználó létezik-e a Firestore-ban
      if (userCredential.user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          // Ha a dokumentum nem létezik, létrehozzuk alapértelmezett értékekkel
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'username': userCredential.user!.displayName ?? 'User',
            'email': userCredential.user!.email,
            'gender': 'Male', // Alapértelmezett nem
            'weight': 70.0, // Alapértelmezett súly (kg)
            'height': 170.0, // Alapértelmezett magasság (cm)
            'birthDate': Timestamp.fromDate(
              DateTime(
                  1990, 1, 1), // Alapértelmezett születési idő (1990.01.01)
            ),
            'dailyCalories': 0,
            'completedWorkouts': 0,
            'profileImageUrl': null, // Kezdetben nincs profilkép
            'role': 'user', // <- EZT ADD HOZZÁ
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
