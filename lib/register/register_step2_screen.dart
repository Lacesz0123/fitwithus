import 'package:flutter/material.dart';
import '../home_screen.dart'; // A főoldalra való navigálás
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterStep2Screen extends StatefulWidget {
  final String email;
  final String username;
  final String password;

  const RegisterStep2Screen({
    super.key,
    required this.email,
    required this.username,
    required this.password,
  });

  @override
  _RegisterStep2ScreenState createState() => _RegisterStep2ScreenState();
}

class _RegisterStep2ScreenState extends State<RegisterStep2Screen> {
  TextEditingController _weightController = TextEditingController();
  TextEditingController _heightController = TextEditingController();
  String _selectedGender = "Male"; // Nem választása
  DateTime? _birthDate; // Születési dátum
  String _errorMessage = '';

  Future<void> _registerUser() async {
    if (_validateInputs()) {
      try {
        // Felhasználó regisztrálása Firebase-ben
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: widget.email,
          password: widget.password,
        );

        // Felhasználói adatok mentése a Firestore-ba
        User? user = userCredential.user;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'email': widget.email,
            'username': widget.username,
            'weight': int.parse(_weightController.text),
            'height': int.parse(_heightController.text),
            'favorites': [], // Üres kedvenc lista létrehozása
            'favoriteRecipes': [], // Üres kedvenc recept lista létrehozása
            'gender': _selectedGender,
            'birthDate': _birthDate?.toIso8601String(),
            'completedWorkouts': 0,
            'role': 'user', // Alapértelmezett szerepkör hozzáadása
          });

          // Sikeres regisztráció után átirányítás a HomeScreen-re
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } catch (e) {
        print("Error during registration: $e");
        setState(() {
          _errorMessage = "An error occurred during registration.";
        });
      }
    }
  }

  bool _validateInputs() {
    if (_weightController.text.isEmpty ||
        _heightController.text.isEmpty ||
        _birthDate == null) {
      setState(() {
        _errorMessage = 'All fields are required.';
      });
      return false;
    }

    // Ellenőrizni a súly és magasság helyességét
    int? weight = int.tryParse(_weightController.text);
    int? height = int.tryParse(_heightController.text);

    if (weight == null || weight <= 0 || weight > 999) {
      setState(() {
        _errorMessage = 'Weight must be a positive number and max 3 digits.';
      });
      return false;
    }

    if (height == null || height < 60 || height > 250) {
      setState(() {
        _errorMessage = 'Height must be between 60 and 250 cm.';
      });
      return false;
    }

    return true;
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Step 2: Additional Information')),
      resizeToAvoidBottomInset:
          true, // Engedélyezi az átrendezést a billentyűzet megjelenésekor
      body: SingleChildScrollView(
        // Görgethető tartalom
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Gender"),
              DropdownButton<String>(
                value: _selectedGender,
                items: const [
                  DropdownMenuItem(value: "Male", child: Text("Male")),
                  DropdownMenuItem(value: "Female", child: Text("Female")),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Your Weight (kg)",
                  prefixIcon: Icon(Icons.fitness_center),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Your Height (cm)",
                  prefixIcon: Icon(Icons.height),
                ),
              ),
              const SizedBox(height: 16.0),
              const Text("Date of Birth"),
              ElevatedButton(
                onPressed: () => _selectBirthDate(context),
                child: Text(_birthDate == null
                    ? "Select Date of Birth"
                    : _birthDate!.toLocal().toString().split(' ')[0]),
              ),
              const SizedBox(height: 16.0),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _registerUser,
                child: const Text("Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
