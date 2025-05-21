import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A `ProfileImageService` osztály profilképek feltöltésére és cseréjére szolgál.
///
/// A képek a Firebase Storage-ban kerülnek tárolásra, és a hivatkozásuk
/// frissítésre kerül a Firestore `users` kollekciójában.
class ProfileImageService {
  /// Képfeltöltés a galériából, majd mentés a Firebase Storage és Firestore rendszerbe.
  ///
  /// - Megnyitja a képválasztót a galériával.
  /// - Ha a `currentImageUrl` paraméter meg van adva, megpróbálja törölni a korábbi képet.
  /// - Feltölti az új képet a `profile_images/userImages/{uid}.jpg` helyre.
  /// - A letöltési linket elmenti a Firestore `users/{uid}` dokumentumba.
  ///
  /// Visszatérési érték: a letöltési URL (`downloadUrl`), vagy `null` hiba vagy megszakítás esetén.
  static Future<String?> uploadProfileImage(User user,
      {String? currentImageUrl}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return null;

    try {
      // Ha van meglévő kép, azt megpróbáljuk törölni
      if (currentImageUrl != null) {
        try {
          final oldImageRef =
              FirebaseStorage.instance.refFromURL(currentImageUrl);
          await oldImageRef.delete();
        } catch (e) {
          print('Error deleting previous profile image: $e');
        }
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/userImages/${user.uid}.jpg');

      await storageRef.putFile(File(pickedFile.path));
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'profileImageUrl': downloadUrl});

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }
}
