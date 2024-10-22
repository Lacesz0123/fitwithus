import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  String? _email;
  String? _username;
  DateTime? _birthdate;
  String? _gender;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

      if (data != null) {
        _email = data['email'] ?? '';
        _username = data['username'] ?? '';
        _birthdate = data['birthDate'] != null
            ? DateTime.parse(data['birthDate'])
            : null;
        _gender = data['gender'] ?? '';
        setState(() {});
      }
    }
  }

  Future<void> _showEditDialog(String field, dynamic currentValue) async {
    TextEditingController controller =
        TextEditingController(text: currentValue is String ? currentValue : '');
    DateTime? newBirthdate = _birthdate;
    String? newGender = _gender;
    String errorMessage = '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $field'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (field == 'Gender')
                DropdownButtonFormField<String>(
                  value: newGender,
                  items: ['Male', 'Female']
                      .map((gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          ))
                      .toList(),
                  onChanged: (value) {
                    newGender = value;
                  },
                  decoration: const InputDecoration(labelText: 'Select Gender'),
                )
              else if (field == 'Birth Date')
                ElevatedButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: newBirthdate ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      newBirthdate = pickedDate;
                      setState(() {
                        _birthdate = newBirthdate;
                      });
                      Navigator.of(context).pop();
                      _updateUserData();
                    }
                  },
                  child: Text(
                    newBirthdate != null
                        ? DateFormat('yyyy. MM. dd.').format(newBirthdate!)
                        : 'Select Date',
                  ),
                )
              else
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Enter $field',
                    errorText: errorMessage.isNotEmpty ? errorMessage : null,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (field == 'Email') {
                  if (!_isValidEmail(controller.text)) {
                    errorMessage = 'Please enter a valid email';
                    _showMessage(errorMessage);
                    return;
                  }
                  if (await _isEmailInUse(controller.text)) {
                    errorMessage = 'Email is already in use';
                    _showMessage(errorMessage);
                    return;
                  }
                  _email = controller.text;
                } else if (field == 'Username') {
                  if (!_isValidUsername(controller.text)) {
                    errorMessage =
                        'Username must be 5-15 characters long and contain only letters and numbers';
                    _showMessage(errorMessage);
                    return;
                  }
                  _username = controller.text;
                } else if (field == 'Gender') {
                  _gender = newGender;
                }

                await _updateUserData();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _isEmailInUse(String email) async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    return result.docs.isNotEmpty && email != _email;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidUsername(String username) {
    final usernameRegex = RegExp(r'^[a-zA-Z0-9]{5,15}$');
    return usernameRegex.hasMatch(username);
  }

  Future<void> _updateUserData() async {
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'email': _email,
        'username': _username,
        'birthDate': _birthdate?.toIso8601String(),
        'gender': _gender,
      });

      await _loadUserData(); // Adatok újratöltése a frissítés után
      _showMessage('Profile updated successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildProfileItem('Email', _email ?? ''),
              const Divider(),
              _buildProfileItem('Username', _username ?? ''),
              const Divider(),
              _buildProfileItem(
                  'Birth Date',
                  _birthdate != null
                      ? DateFormat('yyyy. MM. dd.').format(_birthdate!)
                      : 'Not set'),
              const Divider(),
              _buildProfileItem('Gender', _gender ?? ''),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(String field, String value) {
    return ListTile(
      title: Text(
        field,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(value),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () => _showEditDialog(field, value),
      ),
    );
  }
}
