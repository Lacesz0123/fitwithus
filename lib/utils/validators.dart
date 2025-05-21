import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';

/// A `Validators` osztály statikus metódusokat biztosít különböző
/// bemeneti adatok érvényesítésére, mint például felhasználónév, jelszó,
/// testsúly, testmagasság, születési dátum, recept mezők stb.
class Validators {
  /// Ellenőrzi, hogy a felhasználónév érvényes-e.
  ///
  /// A felhasználónév csak angol betűket és számokat tartalmazhat,
  /// valamint 5 és 15 karakter közötti hosszúságú lehet.
  static bool isUsernameValid(String username) {
    final validCharacters = RegExp(r'^[a-zA-Z0-9]+$');
    return username.length >= 5 &&
        username.length <= 15 &&
        validCharacters.hasMatch(username);
  }

  /// Ellenőrzi, hogy a jelszó legalább 5 karakter hosszú-e.
  static bool isPasswordValid(String password) {
    return password.length >= 5;
  }

  /// Ellenőrzi, hogy a testsúly érvényes-e.
  ///
  /// A súlynak pozitív egész számnak kell lennie, legfeljebb 3 számjeggyel.
  static bool isWeightValid(String weight) {
    final w = int.tryParse(weight);
    return w != null && w > 0 && w <= 999;
  }

  /// Ellenőrzi, hogy a testmagasság érvényes-e.
  ///
  /// A magasságnak 60 és 250 cm közé kell esnie.
  static bool isHeightValid(String height) {
    final h = int.tryParse(height);
    return h != null && h >= 60 && h <= 250;
  }

  /// Kombinált validáció: testsúly, testmagasság és születési dátum ellenőrzése.
  ///
  /// Ha bármelyik mező hiányzik, vagy nem megfelelő formátumú,
  /// egy figyelmeztető szöveges üzenetet ad vissza. Ha minden adat érvényes,
  /// akkor `null` értékkel tér vissza.
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

  /// Regisztráció 1. lépésének validációja.
  ///
  /// Ellenőrzi az email-cím formátumát, a felhasználónév hosszát és karaktereit,
  /// a jelszó hosszát, valamint hogy a jelszavak egyeznek-e.
  ///
  /// Hibás adat esetén hibaüzenetet ad vissza, egyébként `null`-t.
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

  /// Recept szerkesztési mezők validálása.
  ///
  /// Ellenőrzi, hogy a recept neve és leírása nem üres,
  /// az elkészítési idő és kalóriamennyiség számérték, pozitívak-e,
  /// valamint hogy legalább egy hozzávaló és egy lépés meg van-e adva.
  ///
  /// Hibás adat esetén hibaüzenetet ad vissza, különben `null`-t.
  static String? validateEditedRecipe({
    required String name,
    required String description,
    required String prepTime,
    required String calories,
    required List<TextEditingController> ingredients,
    required List<TextEditingController> steps,
  }) {
    if (name.trim().isEmpty) return 'Recipe name cannot be empty.';
    if (description.trim().isEmpty) return 'Description cannot be empty.';

    final parsedPrepTime = int.tryParse(prepTime);
    if (parsedPrepTime == null || parsedPrepTime <= 0) {
      return 'Preparation time must be a valid number.';
    }

    final parsedCalories = int.tryParse(calories);
    if (parsedCalories == null || parsedCalories <= 0) {
      return 'Calories must be a valid positive number.';
    }

    final ingredientList = ingredients
        .map((c) => c.text.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (ingredientList.isEmpty) {
      return 'Please add at least one ingredient.';
    }

    final stepList =
        steps.map((c) => c.text.trim()).where((e) => e.isNotEmpty).toList();
    if (stepList.isEmpty) {
      return 'Please add at least one step.';
    }

    return null; // Minden valid!
  }
}
