import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart'; // Email validátor csomag
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

  bool _isUsernameValid(String username) {
    final validCharacters = RegExp(r'^[a-zA-Z0-9]+$');
    return username.length >= 5 && validCharacters.hasMatch(username);
  }

  void _continueRegistration() {
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
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "Password",
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "Confirm Password",
                  prefixIcon: Icon(Icons.lock),
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
