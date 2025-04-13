import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileImageService {
  static Future<String?> uploadProfileImage(User user,
      {String? currentImageUrl}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return null;

    try {
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
