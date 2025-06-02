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
  final String? status;
  final List<Widget>? actionButtons;

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
    this.status,
    this.actionButtons,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd.MM.yyyy').format(date);
    final bool hasActions = (actionButtons != null && actionButtons!.isNotEmpty) || onDeletePressed != null;

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
                  leading ?? const Icon(Icons.location_on, color: Color(0xFF201731)),
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
                  Text('${'price'.tr()}: ${price.toStringAsFixed(2)} KZT',
                      style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 18, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('${'user'.tr()}: $userLocation',
                        style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14)),
                  ),
                ],
              ),
              if (status != null && status!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: Colors.orangeAccent),
                    const SizedBox(width: 6),
                    Text('${'status'.tr()}: ${status!.tr()}',
                        style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
              if (hasActions) ...[
                 const Divider(height: 20, thickness: 1),
                 Wrap(
                   spacing: 8.0,
                   runSpacing: 4.0,
                   alignment: WrapAlignment.end,
                   children: [
                     if (onDeletePressed != null)
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          label: Text('delete'.tr(), style: const TextStyle(color: Colors.redAccent)),
                          onPressed: onDeletePressed,
                           style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        ),
                    if (actionButtons != null)
                      ...actionButtons!,
                   ],
                 )
              ],
            ],
          ),
        ),
      ),
    );
  }
}