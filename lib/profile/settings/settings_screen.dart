import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import '/utils/custom_snackbar.dart';

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
  int? _height;

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
        setState(() {
          _email = data['email'] ?? user!.email ?? 'No email';
          _username = data['username'] ?? 'User';
          _gender = data['gender'] ?? 'Male';
          _height = (data['height'] as num?)?.toInt() ?? 170;
          if (data['birthDate'] != null) {
            if (data['birthDate'] is Timestamp) {
              _birthdate = (data['birthDate'] as Timestamp).toDate();
            } else if (data['birthDate'] is String) {
              _birthdate = DateTime.tryParse(data['birthDate']);
            }
          }
          _birthdate ??= DateTime(1990, 1, 1);
        });
      } else {
        setState(() {
          _email = user!.email ?? 'No email';
          _username = user!.displayName ?? 'User';
          _gender = 'Male';
          _height = 170;
          _birthdate = DateTime(1990, 1, 1);
        });
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
    TextEditingController controller = TextEditingController(
        text: currentValue is String
            ? currentValue
            : currentValue?.toString() ?? '');
    DateTime? newBirthdate = _birthdate;
    String? newGender = _gender;
    int newHeight = _height ?? 170; // Ideiglenes változó a szerkesztéshez
    String errorMessage = '';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              backgroundColor: Theme.of(context).dialogBackgroundColor,
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.blueAccent,
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
                                ? DateFormat('yyyy. MM. dd.')
                                    .format(newBirthdate!)
                                : 'Select Date',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      )
                    else if (field == 'Height')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove,
                                color: Colors.blueAccent),
                            onPressed: () {
                              setDialogState(() {
                                if (newHeight > 60) {
                                  newHeight--;
                                }
                              });
                            },
                          ),
                          Text(
                            '$newHeight cm',
                            style: const TextStyle(fontSize: 20),
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.add, color: Colors.blueAccent),
                            onPressed: () {
                              setDialogState(() {
                                if (newHeight < 250) {
                                  newHeight++;
                                }
                              });
                            },
                          ),
                        ],
                      )
                    else
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'Enter $field',
                          errorText:
                              errorMessage.isNotEmpty ? errorMessage : null,
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
                              await _updateUsernameInCommunityMessages(
                                  _username!);
                            } else if (field == 'Gender') {
                              _gender = newGender;
                            } else if (field == 'Height') {
                              if (newHeight < 60 || newHeight > 250) {
                                errorMessage =
                                    'Height must be an integer between 60 and 250 cm';
                                _showMessage(errorMessage);
                                return;
                              }
                              _height = newHeight; // Állapot frissítése
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
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    showCustomSnackBar(context, message, isError: isError);
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
        'birthDate':
            _birthdate != null ? Timestamp.fromDate(_birthdate!) : null,
        'gender': _gender,
        'height': _height,
      });

      await _loadUserData();
      _showMessage('Profile updated successfully');
    }
  }

  Future<void> _deleteAccount() async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark
                      ? Theme.of(context).textTheme.bodyLarge?.color
                      : Colors.black,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmDelete) {
      try {
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
          showCustomSnackBar(
              context, 'Your account has been successfully deleted.');
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          showCustomSnackBar(
              context, 'Please log in again to confirm account deletion.');
        } else {
          showCustomSnackBar(context, 'Error: ${e.message}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        flexibleSpace: Theme.of(context).brightness == Brightness.dark
            ? Container(
                color: const Color(0xFF1E1E1E),
              )
            : Container(
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
              Text(
                'Profile Information',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),
              _buildProfileItem('Email', _email ?? 'Loading...',
                  editable: false),
              const Divider(thickness: 1.5),
              _buildProfileItem('Username', _username ?? 'Loading...'),
              const Divider(thickness: 1.5),
              _buildProfileItem(
                'Birth Date',
                _birthdate != null
                    ? DateFormat('yyyy. MM. dd.').format(_birthdate!)
                    : 'Not set',
              ),
              const Divider(thickness: 1.5),
              _buildProfileItem('Gender', _gender ?? 'Loading...'),
              const Divider(thickness: 1.5),
              _buildProfileItem(
                  'Height', _height != null ? '$_height cm' : 'Loading...'),
              const SizedBox(height: 30),
              Text(
                'Appearance',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade800.withOpacity(0.4)
                      : Colors.blueAccent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade600
                        : Colors.blueAccent.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dark Mode',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    Switch.adaptive(
                      value: themeProvider.isDarkMode,
                      onChanged: (bool newValue) {
                        themeProvider.toggleTheme(newValue);
                      },
                      activeColor: Colors.grey.shade700,
                    ),
                  ],
                ),
              ),
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
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      trailing: editable
          ? IconButton(
              icon: Icon(
                Icons.edit,
                color: Theme.of(context).iconTheme.color,
              ),
              onPressed: () => _showEditDialog(field, value),
            )
          : null,
    );
  }
}
