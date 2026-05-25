import 'package:flutter/material.dart';

class AppConstants {
  // Colors
  static const Color backgroundColor = Color(0xFF09090B);
  static const Color cardColor = Color(0xFF18181B);
  static const Color primaryColor = Color(0xFFFF0055);
  static const Color secondaryTextColor = Color(0xFFA1A1AA);
  static const Color borderColor = Color(0xFF27272A);

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    color: Colors.white,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.0,
  );

  static const TextStyle subheadingStyle = TextStyle(
    color: Color(0xFFA1A1AA),
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );

  // Input Decoration
  static InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 14),
      filled: true,
      fillColor: Color(0xFF18181B),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF27272A), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF0055), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  // Button Style
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 0,
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5),
  );

  // API
  static const String baseUrl = 'http://localhost:3000/api';
}