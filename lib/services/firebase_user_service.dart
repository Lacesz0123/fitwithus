// lib/services/firebase_user_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseUserService {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  Future<bool> isEmailInUse(String email) async {
    final querySnapshot =
        await usersCollection.where('email', isEqualTo: email).get();

    return querySnapshot.docs.isNotEmpty;
  }
}
