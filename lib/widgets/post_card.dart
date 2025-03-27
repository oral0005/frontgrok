import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final String from; // Заменено route на from
  final String to;   // Заменено route на to
  final DateTime date;
  final String userLocation;
  final VoidCallback onMorePressed;
  final Widget? leading;

  const PostCard({
    super.key,
    required this.from,
    required this.to,
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
        leading: leading,
        title: Text('$from → $to'), // Обновлено отображение с from и to
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