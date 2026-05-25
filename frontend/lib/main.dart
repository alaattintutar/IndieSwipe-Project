import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
Widget build(BuildContext context) {
  return ProviderScope(
    child: MaterialApp(
      title: 'IndieSwipe',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF09090B),
        body: Center(
          child: Text(
            'IndieSwipe',
            style: TextStyle(
              color: Color(0xFFFF0055),
              fontSize: 32,
            ),
          ),
        ),
      ),
    ),
  );
}
}