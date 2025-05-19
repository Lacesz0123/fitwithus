import 'package:flutter/material.dart';
import 'package:fitwithus/pages/workouts/in_a_category/in_a_category_list_workouts_screen.dart';

class WorkoutCategoryCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String docId;
  final String? userRole;
  final void Function()? onEditTap;

  const WorkoutCategoryCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.docId,
    required this.userRole,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryWorkoutsScreen(category: title),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Háttérkép network-ről + loading közbeni spinner
              Positioned.fill(
                child: Image.network(
                  imageUrl.isNotEmpty
                      ? imageUrl
                      : 'https://firebasestorage.googleapis.com/v0/b/fitwithus-c4ae9.appspot.com/o/category_images%2FplaceholderImage%2Fplaceholder.jpg?alt=media&token=bd57247b-4a73-ac18-3d5d93b15960',
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.white : Colors.blueAccent,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/offline_placeholder.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Fade overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black87],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              // Title
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              // Admin szerkesztés ikon
              if (userRole == 'admin')
                Positioned(
                  top: 10,
                  right: 10,
                  child: InkWell(
                    onTap: onEditTap,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(1, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.settings,
                        color: isDark ? Colors.white : Colors.blueAccent,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
