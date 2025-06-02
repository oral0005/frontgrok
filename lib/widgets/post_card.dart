import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

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
    final formattedDate = DateFormat('dd.MM.yyyy').format(date);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onMorePressed,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF201731)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      from.tr(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                        color: Color(0xFF201731),
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward, color: Colors.grey),
                  Expanded(
                    child: Text(
                      to.tr(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                        color: Color(0xFF201731),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const Icon(Icons.location_on, color: Color(0xFF201731)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('${'date'.tr()}: $formattedDate',
                      style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14)),
                  const Spacer(),
                  const SizedBox(width: 4),
                  Text('${'price'.tr()}: ${price.toStringAsFixed(2)} KZT',
                      style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 18, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('${'user'.tr()}: $userLocation',
                        style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14)),
                  ),
                ],
              ),
              if (onDeletePressed != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDeletePressed,
                    ),
                  ],
                ),
              ],
              const Divider(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onMorePressed,
                  icon: const Icon(Icons.info_outline, color: Color(0xFF201731)),
                  label: Text('details'.tr(), style: const TextStyle(fontFamily: 'Montserrat', color: Color(0xFF201731))),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF201731),
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