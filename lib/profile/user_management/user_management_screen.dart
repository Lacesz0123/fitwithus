import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/utils/custom_snackbar.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  Future<void> _disableUser(BuildContext context, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'disabled': true,
      });
      showCustomSnackBar(context, 'User disabled successfully');
    } catch (e) {
      showCustomSnackBar(context, 'Error disabling user: $e', isError: true);
    }
  }

  Future<void> _enableUser(BuildContext context, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'disabled': false,
      });
      showCustomSnackBar(context, 'User enabled successfully');
    } catch (e) {
      showCustomSnackBar(context, 'Error enabling user: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        flexibleSpace: Theme.of(context).brightness == Brightness.dark
            ? Container(color: const Color(0xFF1E1E1E))
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          final users = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;
              final username = data['username'] ?? 'Unnamed User';
              final email = data['email'] ?? 'No email';
              final disabled = data['disabled'] == true;

              return ListTile(
                title: Text(username),
                subtitle: Text(email),
                trailing: ElevatedButton(
                  onPressed: () {
                    if (disabled) {
                      _enableUser(context, user.id);
                    } else {
                      _disableUser(context, user.id);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: disabled ? Colors.green : Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(disabled ? 'Enable' : 'Disable'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
