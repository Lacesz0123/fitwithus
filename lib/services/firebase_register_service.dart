import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// A `FirebaseRegisterService` osztály felelős új felhasználók regisztrálásáért,
/// valamint a hozzájuk tartozó adatok Firestore-ba mentéséért.
class FirebaseRegisterService {
  final FirebaseAuth _auth;
  final CollectionReference _users;

  /// Alapértelmezett konstruktor, amely a `FirebaseAuth.instance` és a
  /// `users` nevű Firestore kollekció használatával dolgozik.
  FirebaseRegisterService()
      : _auth = FirebaseAuth.instance,
        _users = FirebaseFirestore.instance.collection('users');

  /// Teszteléshez használható konstruktor, amelynél a `FirebaseAuth` és
  /// `CollectionReference` példányokat kívülről lehet megadni.
  ///
  /// Hasznos unit tesztelés során, ahol `mock` vagy `fake` példányokat használunk.
  @visibleForTesting
  FirebaseRegisterService.test({
    required FirebaseAuth auth,
    required CollectionReference usersCollection,
  })  : _auth = auth,
        _users = usersCollection;

  /// Új felhasználó regisztrálása email és jelszó alapján.
  ///
  /// A regisztráció során:
  /// - Létrejön a Firebase Authentication fiók
  /// - Verifikációs emailt küldünk a felhasználónak
  /// - A `users/{uid}` dokumentumban tároljuk a felhasználó adatait
  ///
  /// Paraméterek:
  /// - `email`: a felhasználó email címe
  /// - `password`: a választott jelszó
  /// - `username`: a megjelenítendő név
  /// - `weight`: testsúly (kg)
  /// - `height`: testmagasság (cm)
  /// - `gender`: nem
  /// - `birthDate`: születési dátum
  ///
  /// Visszatérési érték: a létrehozott `User` példány, vagy `null` ha sikertelen.
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
