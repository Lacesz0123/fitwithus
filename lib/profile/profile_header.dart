import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String? profileImageUrl;
  final String? defaultProfileImageUrl;
  final VoidCallback onImageTap;
  final String username;
  final String? subtitle; // <- ÚJ

  const ProfileHeader(
      {super.key,
      required this.profileImageUrl,
      required this.defaultProfileImageUrl,
      required this.onImageTap,
      required this.username,
      this.subtitle // <- ÚJ
      });

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = profileImageUrl ?? defaultProfileImageUrl;

    return Column(
      children: [
        const SizedBox(height: 30),
        GestureDetector(
          onTap: onImageTap,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : null,
              gradient: Theme.of(context).brightness == Brightness.dark
                  ? null
                  : const LinearGradient(
                      colors: [Colors.tealAccent, Colors.blueAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.6)
                      : Colors.grey.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(5),
            child: CircleAvatar(
              radius: 65,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade900
                  : Colors.white,
              child: imageUrl != null
                  ? ClipOval(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: 130,
                        height: 130,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          size: 70,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : const Icon(Icons.person, size: 70, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          username,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
