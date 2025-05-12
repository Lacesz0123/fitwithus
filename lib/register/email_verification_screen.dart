import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../bottom_nav_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _checking = false;

  Future<void> _checkEmailVerification() async {
    setState(() => _checking = true);
    User? user = FirebaseAuth.instance.currentUser;

    await user?.reload(); // frissíti az email hitelesítési állapotot
    if (user != null && user.emailVerified) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const BottomNavScreen()),
        (route) => false,
      );
    } else {
      setState(() => _checking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your email is not verified yet.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email_outlined,
                size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Please verify your email address to continue.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'A verification link has been sent to your email.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _checking ? null : _checkEmailVerification,
              icon: const Icon(Icons.refresh),
              label: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
