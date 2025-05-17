import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final Color? color;
  final bool obscureText; // Added obscureText parameter

  const CustomTextField({
    required this.label,
    this.controller,
    this.keyboardType,
    this.color,
    this.obscureText = false, // Default to false
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText, // Pass obscureText to TextField
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: color ?? Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        labelStyle: const TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w600, // SemiBold for labels
        ),
      ),
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w400, // Regular for input text
        color: color != null ? Colors.white : Colors.black,
      ),
    );
  }
}