// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../bottom_nav_screen.dart';
import '../register/register_step1_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

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

  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _signIn() async {
    setState(() => _errorMessage = '');

    final hasInternet = await hasInternetConnection();
    if (!hasInternet) {
      setState(() => _errorMessage =
          'No internet connection. You can only use the app as a guest.');
      return;
    }

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
        // Ellenőrzés Firestore-ban, hogy nincs-e letiltva
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        final userData = userDoc.data();
        if (userData != null && userData['disabled'] == true) {
          await FirebaseAuth.instance.signOut();
          setState(() {
            _errorMessage =
                'This account has been disabled by an administrator.';
          });
          return;
        }

        // Minden rendben, továbbengedjük
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const BottomNavScreen()),
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

  Future<void> _signInAsGuest() async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) {
      setState(() {
        _errorMessage =
            'No internet connection. You can only use the app as a guest.';
      });
      // Itt nem próbáljuk meg a Firebase Auth-ot elérni!
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const BottomNavScreen()),
      );
      return;
    }

    try {
      UserCredential userCredential = await _authService.signInAnonymously();
      if (userCredential.user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const BottomNavScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to sign in as guest.';
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _errorMessage = '');

    final hasInternet = await hasInternetConnection();
    if (!hasInternet) {
      setState(() => _errorMessage =
          'No internet connection. You can only use the app as a guest.');
      return;
    }

    try {
      UserCredential? userCredential = await _authService.signInWithGoogle();
      if (userCredential != null && userCredential.user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        final userData = userDoc.data();
        if (userData != null && userData['disabled'] == true) {
          await FirebaseAuth.instance.signOut();
          setState(() {
            _errorMessage =
                'This account has been disabled by an administrator.';
          });
          return;
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const BottomNavScreen()),
        );
      } else {
        setState(() => _errorMessage = 'Google Sign-In was cancelled.');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = 'Firebase Auth Error: ${e.message}');
    } catch (e) {
      setState(() {
        _errorMessage = 'Google Sign-In failed. Please try again.';
      });
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address.';
      });
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Please check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = switch (e.code) {
          'user-not-found' => 'No user found with this email.',
          'invalid-email' => 'Invalid email format.',
          _ => 'Failed to send reset email: ${e.message}',
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: ThemeData.light(), // ← force light mode
        child: Scaffold(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "FitWithUs",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                12), // itt állíthatod a kerekítés mértékét
                            child: Image.asset(
                              'assets/logo.png',
                              height: 70,
                              width: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
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
                          prefixIcon:
                              const Icon(Icons.lock, color: Colors.black54),
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
                    const SizedBox(height: 5.0),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () async {
                          final hasInternet = await hasInternetConnection();
                          if (!hasInternet) {
                            setState(() {
                              _errorMessage =
                                  'No internet connection. You can only use the app as a guest.';
                            });
                            return;
                          }
                          _sendPasswordResetEmail();
                        },
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
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
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _errorMessage.isNotEmpty
                          ? Container(
                              key: ValueKey(_errorMessage),
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16.0),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14.0, horizontal: 16.0),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(color: Colors.redAccent),
                              ),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start, // fontos!
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.redAccent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20.0),
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final hasInternet = await hasInternetConnection();
                          if (!hasInternet) {
                            setState(() {
                              _errorMessage =
                                  'No internet connection. You can only use the app as a guest.';
                            });
                            return;
                          }

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RegisterStep1Screen(),
                            ),
                          );
                        },
                        child: Text.rich(
                          TextSpan(
                            text: "Don't have an account? ",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                            ),
                            children: [
                              TextSpan(
                                text: "Register here.",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: const [
                        Expanded(
                          child: Divider(
                            color: Colors.white,
                            thickness: 1,
                            indent: 10,
                            endIndent: 10,
                          ),
                        ),
                        Text(
                          "Or",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white,
                            thickness: 1,
                            indent: 10,
                            endIndent: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _signInAsGuest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.person_outline,
                            color: Colors.white),
                        label: const Text(
                          "Continue as Guest",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _signInWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.g_mobiledata,
                            color: Colors.black87),
                        label: const Text(
                          "Continue with Google",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
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
        ));
  }
}
