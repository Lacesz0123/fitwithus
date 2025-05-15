import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // csak a teszt konstruktorhoz

class FirebaseAuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  // Alapértelmezett konstruktor (appban használt)
  FirebaseAuthService()
      : _auth = FirebaseAuth.instance,
        _googleSignIn = GoogleSignIn();

  // Csak teszteléshez – mock példányokkal
  @visibleForTesting
  FirebaseAuthService.test({
    required FirebaseAuth auth,
    required GoogleSignIn googleSignIn,
  })  : _auth = auth,
        _googleSignIn = googleSignIn;

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
