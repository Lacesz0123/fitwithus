import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart'; // Email validátor csomag
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore importálása
import 'register_step2_screen.dart'; // Importáljuk a második regisztrációs oldalt

class RegisterStep1Screen extends StatefulWidget {
  const RegisterStep1Screen({super.key});

  @override
  _RegisterStep1ScreenState createState() => _RegisterStep1ScreenState();
}

class _RegisterStep1ScreenState extends State<RegisterStep1Screen> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _usernameController =
      TextEditingController(); // Felhasználónév mező
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();
  String _errorMessage = '';
  bool _passwordVisible = false; // Jelszó láthatóságának állapota
  bool _confirmPasswordVisible =
      false; // Jelszó megerősítés láthatóságának állapota

  bool _isUsernameValid(String username) {
    final validCharacters = RegExp(r'^[a-zA-Z0-9]+$');
    return username.length >= 5 && validCharacters.hasMatch(username);
  }

  Future<void> _continueRegistration() async {
    setState(() {
      _errorMessage = ''; // Üzenet resetelése minden ellenőrzés előtt
    });

    // Email validáció
    if (!EmailValidator.validate(_emailController.text)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address.';
      });
      return;
    }

    // Felhasználónév ellenőrzés
    if (!_isUsernameValid(_usernameController.text)) {
      setState(() {
        _errorMessage =
            'Username must be at least 5 characters long and contain only letters and numbers.';
      });
      return;
    }

    // Jelszó hosszúság ellenőrzés
    if (_passwordController.text.length < 5) {
      setState(() {
        _errorMessage = 'Password must be at least 5 characters long.';
      });
      return;
    }

    // Jelszó és megerősítés ellenőrzés
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    // Ellenőrizzük, hogy az e-mail cím már létezik-e
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _emailController.text)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _errorMessage = 'Email is already in use.';
        });
        return;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking email existence: $e';
      });
      return;
    }

    // Továbblépés a következő oldalra
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RegisterStep2Screen(
          email: _emailController.text,
          username: _usernameController.text,
          password: _passwordController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Step 1: Basic Information')),
      resizeToAvoidBottomInset:
          true, // Engedélyezi az átrendezést a billentyűzet megjelenésekor
      body: SingleChildScrollView(
        // Görgethető tartalom
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: "Email",
                  prefixIcon: Icon(Icons.mail),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _usernameController, // Felhasználónév mező
                decoration: const InputDecoration(
                  hintText: "Username",
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  hintText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_confirmPasswordVisible,
                decoration: InputDecoration(
                  hintText: "Confirm Password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _confirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _confirmPasswordVisible = !_confirmPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              if (_errorMessage.isNotEmpty)
                Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _continueRegistration, // Továbblépés gomb
                child: const Text("Continue"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
