import 'package:flutter/material.dart';
import 'package:fitwithus/workouts/category/category_workouts_screen.dart';

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
    return Stack(
      children: [
        GestureDetector(
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
              borderRadius: BorderRadius.circular(15.0),
              image: DecorationImage(
                image: imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : const NetworkImage(
                        'https://firebasestorage.googleapis.com/v0/b/fitwithus-c4ae9.appspot.com/o/category_images%2FplaceholderImage%2Fplaceholder.jpg?alt=media&token=bd57247b-4a73-ac18-3d5d93b15960'),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15.0),
                    topRight: Radius.circular(15.0),
                  ),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
        if (userRole == 'admin')
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onEditTap,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6.0),
                child: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 24.0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
