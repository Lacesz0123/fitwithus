// lib/utils/validators.dart

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
}
