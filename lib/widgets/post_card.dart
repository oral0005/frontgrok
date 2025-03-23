import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final String route;
  final DateTime date;
  final String userLocation;
  final VoidCallback onMorePressed;
  final Widget? leading; // Add leading widget for icon

  const PostCard({
    super.key,
    required this.route,
    required this.date,
    required this.userLocation,
    required this.onMorePressed,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: leading, // Display the icon (sender or courier)
        title: Text(route),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${date.toString().split(' ')[0]}'),
            Text('User: $userLocation'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: onMorePressed,
        ),
      ),
    );
  }
}