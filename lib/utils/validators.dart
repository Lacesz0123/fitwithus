// lib/utils/validators.dart
import 'package:email_validator/email_validator.dart';

class Validators {
  static bool isUsernameValid(String username) {
    final validCharacters = RegExp(r'^[a-zA-Z0-9]+$');
    return username.length >= 5 &&
        username.length <= 15 &&
        validCharacters.hasMatch(username);
  }

  static bool isPasswordValid(String password) {
    return password.length >= 5;
  }

  static bool isWeightValid(String weight) {
    final w = int.tryParse(weight);
    return w != null && w > 0 && w <= 999;
  }

  static bool isHeightValid(String height) {
    final h = int.tryParse(height);
    return h != null && h >= 60 && h <= 250;
  }

  ///  Kombinált validáció hibaüzenettel
  static String? validateWeightHeightAndBirthDate({
    required String weightText,
    required String heightText,
    required DateTime? birthDate,
  }) {
    if (weightText.isEmpty || heightText.isEmpty || birthDate == null) {
      return 'All fields are required.';
    }

    if (!isWeightValid(weightText)) {
      return 'Weight must be a positive number and max 3 digits.';
    }

    if (!isHeightValid(heightText)) {
      return 'Height must be between 60 and 250 cm.';
    }

    return null; // minden OK
  }

  /// 👤 Kombinált validáció a regisztráció 1. lépéshez
  static String? validateRegisterStep1({
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
  }) {
    if (!EmailValidator.validate(email)) {
      return 'Please enter a valid email address.';
    }

    if (!isUsernameValid(username)) {
      return 'Username must be 5-15 characters long and contain only letters and numbers.';
    }

    if (!isPasswordValid(password)) {
      return 'Password must be at least 5 characters long.';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match.';
    }

    return null;
  }
}
