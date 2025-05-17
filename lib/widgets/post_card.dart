import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final String from;
  final String to;
  final DateTime date;
  final String userLocation;
  final double price;
  final VoidCallback onMorePressed;
  final VoidCallback? onDeletePressed;
  final Widget? leading;

  const PostCard({
    super.key,
    required this.from,
    required this.to,
    required this.date,
    required this.userLocation,
    required this.price,
    required this.onMorePressed,
    this.onDeletePressed,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: leading,
        title: Text('$from → $to'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${date.toString().split(' ')[0]}'),
            Text('User: $userLocation'),
            Text('Price: ${price.toStringAsFixed(2)} KZT'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: onMorePressed,
            ),
            if (onDeletePressed != null)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDeletePressed,
              ),
          ],
        ),
      ),
    );
  }
}