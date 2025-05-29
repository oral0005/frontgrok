import 'package:flutter/material.dart';
import '../models/post.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

String getAvatarUrl(String? avatarUrl) {
  if (avatarUrl == null || avatarUrl.isEmpty) return '';
  if (avatarUrl.startsWith('http')) return avatarUrl;
  return '$serverBaseUrl$avatarUrl';
}

class PostDetailsPopup {
  static void show(BuildContext context, Post post) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    post.type == 'sender' ? Icons.send : Icons.local_shipping,
                    color: post.type == 'sender' ? Color(0xFF201731) : Color(0xFF201731),
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${post.from.tr()} → ${post.to.tr()}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Montserrat', color: Color(0xFF201731)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(DateFormat('dd.MM.yyyy').format(post.date), style: const TextStyle(fontFamily: 'Montserrat', fontSize: 15)),
                  const Spacer(),
                  Icon(Icons.attach_money, size: 18, color: Colors.green[700]),
                  const SizedBox(width: 4),
                  Text('${post.price.toStringAsFixed(2)} KZT', style: const TextStyle(fontFamily: 'Montserrat', fontSize: 15, color: Colors.green)),
                ],
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: (post.avatarUrl != null && post.avatarUrl!.isNotEmpty)
                          ? NetworkImage(getAvatarUrl(post.avatarUrl))
                          : null,
                        child: (post.avatarUrl == null || post.avatarUrl!.isEmpty)
                          ? Icon(Icons.person, size: 28, color: Colors.blueGrey[700])
                          : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(post.userLocation, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Montserrat', fontSize: 16)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(post.phoneNumber ?? 'not_provided'.tr(), style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(post.type == 'sender' ? 'sender'.tr() : 'courier'.tr(), style: const TextStyle(fontFamily: 'Montserrat', fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: Colors.red[400]),
                    const SizedBox(width: 6),
                    Text('${'from'.tr()}: ${post.from.tr()}', style: const TextStyle(fontFamily: 'Montserrat', fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.flag, size: 18, color: Colors.green[400]),
                    const SizedBox(width: 6),
                    Text('${'to'.tr()}: ${post.to.tr()}', style: const TextStyle(fontFamily: 'Montserrat', fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 14),
                Text('description'.tr(), style: const TextStyle(fontSize: 15, color: Colors.grey, fontFamily: 'Montserrat')),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    post.description.isEmpty ? 'no_description'.tr() : post.description,
                    style: const TextStyle(fontFamily: 'Montserrat', fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (post.phoneNumber != null && post.phoneNumber!.isNotEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.phone, color: Colors.white),
                label: Text('call'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _callPhone(context, post.phoneNumber!),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('cancel'.tr(), style: const TextStyle(color: Colors.red)),
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

  static void _callPhone(BuildContext context, String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch dialer')),
      );
    }
  }
}