// lib/services/firebase_register_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseRegisterService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _users =
      FirebaseFirestore.instance.collection('users');

  Future<User?> registerUser({
    required String email,
    required String password,
    required String username,
    required int weight,
    required int height,
    required String gender,
    required DateTime birthDate,
  }) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = userCredential.user;
    if (user != null) {
      await _users.doc(user.uid).set({
        'email': email,
        'username': username,
        'weight': weight,
        'height': height,
        'favorites': [],
        'favoriteRecipes': [],
        'gender': gender,
        'birthDate': birthDate.toIso8601String(),
        'completedWorkouts': 0,
        'role': 'user',
      });
    }

    return user;
  }
}
