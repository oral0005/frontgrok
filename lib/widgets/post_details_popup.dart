import 'package:flutter/material.dart';
import '../models/post.dart';

class PostDetailsPopup {
  static void show(BuildContext context, Post post) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(
                post.type == 'sender' ? Icons.send : Icons.local_shipping,
                color: post.type == 'sender' ? Colors.blue : Colors.green,
                size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${post.from} → ${post.to}', // Обновлено с from и to
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailField('Type', post.type == 'sender' ? 'Sender' : 'Courier'),
                _buildDetailField('From', post.from),           // Заменено Route на From
                _buildDetailField('To', post.to),               // Добавлено To
                _buildDetailField('Date', post.date.toString().split('.')[0]),
                _buildDetailField('User', post.userLocation),
                _buildDetailField('Price', '${post.price.toStringAsFixed(2)} KZT'),
                _buildDetailField('Description', post.description.isEmpty ? 'No description' : post.description),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildDetailField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}