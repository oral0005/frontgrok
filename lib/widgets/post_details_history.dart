import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/post.dart';
import '../services/api_service.dart';

String getAvatarUrl(String? avatarUrl) {
  if (avatarUrl == null || avatarUrl.isEmpty) return '';
  if (avatarUrl.startsWith('http')) return avatarUrl;
  return '${ApiService.baseUrl}/$avatarUrl';
}

class PostDetailsHistoryAssigned {
  static void show(BuildContext context, Post post, {String? assignedSender, String? assignedCourier}) {
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.person, size: 18, color: Colors.blueGrey),

                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (assignedSender != null)
                              Text(
                                '${'sender'.tr()}: $assignedSender',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Montserrat',
                                  color: Color(0xFF201731),
                                ),
                              ),
                            if (assignedCourier != null)
                              Text(
                                '${'courier'.tr()}: $assignedCourier',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Montserrat',
                                  color: Color(0xFF201731),
                                ),
                              ),

                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1, color: Colors.grey),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.person, size: 18, color: Colors.blueGrey),
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

                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1, color: Colors.grey),
                  const SizedBox(height: 16),
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
            style: const TextStyle(fontSize: 14, fontFamily: 'Montserrat', color: Colors.black87),
          ),
        ),
      ],
    );
  }
}