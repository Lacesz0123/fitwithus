// lib/screens/register/register_step1_screen.dart

import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'register_step2_screen.dart';
import '../../services/firebase_user_service.dart';
import '../../utils/validators.dart';

class RegisterStep1Screen extends StatefulWidget {
  const RegisterStep1Screen({super.key});

  @override
  State<RegisterStep1Screen> createState() => _RegisterStep1ScreenState();
}

class _RegisterStep1ScreenState extends State<RegisterStep1Screen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final FirebaseUserService _userService = FirebaseUserService();

  String _errorMessage = '';
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  Future<void> _continueRegistration() async {
    setState(() {
      _errorMessage = '';
    });

    if (!EmailValidator.validate(_emailController.text)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address.';
      });
      return;
    }

    if (!Validators.isUsernameValid(_usernameController.text)) {
      setState(() {
        _errorMessage =
            'Username must be 5-15 characters long and contain only letters and numbers.';
      });
      return;
    }

    if (_passwordController.text.length < 5) {
      setState(() {
        _errorMessage = 'Password must be at least 5 characters long.';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    try {
      final emailExists =
          await _userService.isEmailInUse(_emailController.text);

      if (emailExists) {
        setState(() {
          _errorMessage = 'Email is already in use.';
        });
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RegisterStep2Screen(
            email: _emailController.text,
            username: _usernameController.text,
            password: _passwordController.text,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking email existence: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Information'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.tealAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Let's get started!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Please enter your basic information to create an account.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _emailController,
              hintText: "Email",
              icon: Icons.mail,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _usernameController,
              hintText: "Username",
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              hintText: "Password",
              icon: Icons.lock,
              obscureText: !_passwordVisible,
              toggleVisibility: () {
                setState(() {
                  _passwordVisible = !_passwordVisible;
                });
              },
              isPasswordField: true,
              isVisible: _passwordVisible,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _confirmPasswordController,
              hintText: "Confirm Password",
              icon: Icons.lock,
              obscureText: !_confirmPasswordVisible,
              toggleVisibility: () {
                setState(() {
                  _confirmPasswordVisible = !_confirmPasswordVisible;
                });
              },
              isPasswordField: true,
              isVisible: _confirmPasswordVisible,
            ),
            const SizedBox(height: 16),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _continueRegistration,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool isPasswordField = false,
    VoidCallback? toggleVisibility,
    bool isVisible = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.teal),
        suffixIcon: isPasswordField
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: toggleVisibility,
              )
            : null,
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
