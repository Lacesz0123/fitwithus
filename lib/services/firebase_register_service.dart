import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseRegisterService {
  final FirebaseAuth _auth;
  final CollectionReference _users;

  FirebaseRegisterService()
      : _auth = FirebaseAuth.instance,
        _users = FirebaseFirestore.instance.collection('users');

  @visibleForTesting
  FirebaseRegisterService.test({
    required FirebaseAuth auth,
    required CollectionReference usersCollection,
  })  : _auth = auth,
        _users = usersCollection;

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
      await user.sendEmailVerification();
      await _users.doc(user.uid).set({
        'email': email,
        'username': username,
        'weight': weight,
        'height': height,
        'favorites': [],
        'favoriteRecipes': [],
        'gender': gender,
        'birthDate': Timestamp.fromDate(birthDate),
        'completedWorkouts': 0,
        'role': 'user',
      });
    }

    return user;
  }
}
