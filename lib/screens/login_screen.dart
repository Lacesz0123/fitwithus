// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import '../register/register_step1_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isPasswordVisible = false;

  Future<void> _signIn() async {
    setState(() => _errorMessage = '');

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in both email and password.');
      return;
    }

    try {
      UserCredential userCredential = await _authService.signIn(
        _emailController.text,
        _passwordController.text,
      );

      if (userCredential.user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = switch (e.code) {
          'user-not-found' => 'No user found for this email.',
          'wrong-password' => 'Incorrect password. Please try again.',
          'invalid-email' => 'The email address is badly formatted.',
          'user-disabled' => 'This user has been disabled.',
          'too-many-requests' => 'Too many login attempts. Try again later.',
          _ => 'An error occurred: ${e.message}',
        };
      });
    } catch (_) {
      setState(() => _errorMessage = 'An unknown error occurred.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.tealAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "FitWithUs",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "Login",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26.0,
                  ),
                ),
                const SizedBox(height: 30.0),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5.0,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(16.0),
                      hintText: "User Email",
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.mail, color: Colors.black54),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5.0,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(16.0),
                      hintText: "User Password",
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.lock, color: Colors.black54),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.black54,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RegisterStep1Screen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Don't have an account? Register here.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
