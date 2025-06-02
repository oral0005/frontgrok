import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/post.dart';
import '../services/api_service.dart';

String getAvatarUrl(String? avatarUrl) {
  if (avatarUrl == null || avatarUrl.isEmpty) return '';
  if (avatarUrl.startsWith('http')) return avatarUrl;
  return '${ApiService.baseUrl}/$avatarUrl';
}

class PostDetailsPopup {
  static void show(BuildContext context, Post post) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFFFEF7FF),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with route and post type
                  Row(
                    children: [
                      Icon(
                        post.type == 'sender' ? Icons.send : Icons.local_shipping,
                        color: const Color(0xFF201731),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${post.from.tr()} → ${post.to.tr()}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                            color: Color(0xFF201731),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF201731)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Date and Price
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd.MM.yyyy').format(post.date),
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Montserrat',
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),

                      Text(
                        '${post.price.toStringAsFixed(0)} KZT',
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Montserrat',
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1, color: Colors.grey),
                  // User Information
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: (post.avatarUrl != null && post.avatarUrl!.isNotEmpty)
                            ? NetworkImage(getAvatarUrl(post.avatarUrl))
                            : null,
                        child: (post.avatarUrl == null || post.avatarUrl!.isEmpty)
                            ? const Icon(Icons.person, size: 30, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.userLocation,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Montserrat',
                                color: Color(0xFF201731),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  post.phoneNumber ?? 'not_provided'.tr(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Montserrat',
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Post Details
                  Text(
                    'details'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Montserrat',
                      color: Color(0xFF201731),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.location_on, '${'from'.tr()}: ${post.from.tr()}', Colors.red[400]!),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.location_on, '${'to'.tr()}: ${post.to.tr()}', Colors.blue[400]!),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.info_outline,
                    '${'type'.tr()}: ${post.type == 'sender' ? 'sender'.tr() : 'courier'.tr()}',
                    Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.description,
                    '${'description'.tr()}: ${post.description.isEmpty ? 'no_description'.tr() : post.description}',
                    Colors.grey,
                  ),
                  const SizedBox(height: 24),
                  // Contact Button
                  if (post.phoneNumber != null && post.phoneNumber!.isNotEmpty)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final url = 'tel:${post.phoneNumber}';
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'cannot_launch_phone'.tr(),
                                  style: const TextStyle(fontFamily: 'Montserrat'),
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.phone, size: 18),
                        label: Text('contact'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF201731),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildDetailRow(IconData icon, String text, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Montserrat',
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}