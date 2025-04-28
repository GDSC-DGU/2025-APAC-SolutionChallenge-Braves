import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Braves',
      theme: ThemeData(
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
    );
  }
}