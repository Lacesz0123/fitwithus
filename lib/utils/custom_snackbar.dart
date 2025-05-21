import 'package:flutter/material.dart';

/// Egy lebegő stílusú SnackBar megjelenítésére szolgáló segédfüggvény.
///
/// A `message` paraméter határozza meg a megjelenítendő szöveget.
///
/// Az `isError` opciós paraméter segítségével megadható, hogy
/// hibajelzésről van-e szó. Ebben az esetben a háttér piros színű lesz.

void showCustomSnackBar(BuildContext context, String message,
    {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.black),
      ),
      backgroundColor: isError ? Colors.redAccent : Colors.blueAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      duration: const Duration(seconds: 3),
    ),
  );
}
