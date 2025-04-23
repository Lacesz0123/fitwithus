import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  Future<void> _updateUsernameInCommunityMessages(String newUsername) async {
    if (user == null) return;

    final messages = await FirebaseFirestore.instance
        .collection('community_messages')
        .where('senderId', isEqualTo: user!.uid)
        .get();

    for (var doc in messages.docs) {
      await doc.reference.update({'username': newUsername});
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
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit $field',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 20),
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
                    decoration: const InputDecoration(
                      labelText: 'Select Gender',
                      border: OutlineInputBorder(),
                    ),
                  )
                else if (field == 'Birth Date')
                  Center(
                    child: ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        newBirthdate != null
                            ? DateFormat('yyyy. MM. dd.').format(newBirthdate!)
                            : 'Select Date',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  )
                else
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Enter $field',
                      errorText: errorMessage.isNotEmpty ? errorMessage : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                      ),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (field == 'Username') {
                          if (!_isValidUsername(controller.text)) {
                            errorMessage =
                                'Username must be 5–15 characters long and contain only letters and numbers';
                            _showMessage(errorMessage);
                            return;
                          }
                          _username = controller.text;
                          await _updateUsernameInCommunityMessages(_username!);
                        } else if (field == 'Gender') {
                          _gender = newGender;
                        }

                        await _updateUserData();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("Save"),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.blueAccent,
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

      await _loadUserData();
      _showMessage('Profile updated successfully');
    }
  }

  Future<void> _deleteAccount() async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete) {
      try {
        // Profilkép törlés
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
        final data = doc.data();
        final profileImageUrl = data?['profileImageUrl'];

        if (profileImageUrl != null && profileImageUrl.toString().isNotEmpty) {
          try {
            final imageRef =
                FirebaseStorage.instance.refFromURL(profileImageUrl);
            await imageRef.delete();
          } catch (e) {
            print('Error deleting profile image: $e');
          }
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .delete();

        await user!.delete();
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Your account has been successfully deleted.',
                style: TextStyle(color: Colors.black),
              ),
              backgroundColor: Colors.blueAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              elevation: 6,
              margin: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please log in again to confirm account deletion.',
                style: TextStyle(color: Colors.black),
              ),
              backgroundColor: Colors.blueAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              elevation: 6,
              margin: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${e.message}',
                style: const TextStyle(color: Colors.black),
              ),
              backgroundColor: Colors.blueAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              elevation: 6,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile Information',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),
              _buildProfileItem('Email', _email ?? '', editable: false),
              const Divider(thickness: 1.5),
              _buildProfileItem('Username', _username ?? ''),
              const Divider(thickness: 1.5),
              _buildProfileItem(
                'Birth Date',
                _birthdate != null
                    ? DateFormat('yyyy. MM. dd.').format(_birthdate!)
                    : 'Not set',
              ),
              const Divider(thickness: 1.5),
              _buildProfileItem('Gender', _gender ?? ''),
              const SizedBox(height: 40),
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text(
                    'Delete Account',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  onPressed: _deleteAccount,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(String field, String value, {bool editable = true}) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      title: Text(
        field,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
      trailing: editable
          ? IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueAccent),
              onPressed: () => _showEditDialog(field, value),
            )
          : null,
    );
  }
}
