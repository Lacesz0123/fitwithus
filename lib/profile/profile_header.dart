import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String? profileImageUrl;
  final String? defaultProfileImageUrl;
  final VoidCallback onImageTap;
  final String username;

  const ProfileHeader({
    super.key,
    required this.profileImageUrl,
    required this.defaultProfileImageUrl,
    required this.onImageTap,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        GestureDetector(
          onTap: onImageTap,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Colors.tealAccent, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(5),
            child: CircleAvatar(
              radius: 65,
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl!)
                  : (defaultProfileImageUrl != null
                      ? NetworkImage(defaultProfileImageUrl!)
                      : null),
              backgroundColor: Colors.white,
              child: profileImageUrl == null && defaultProfileImageUrl == null
                  ? const Icon(Icons.person, size: 70, color: Colors.grey)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          username,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
