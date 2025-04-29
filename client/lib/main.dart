import 'package:flutter/material.dart';
import 'screens/view/main_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Braves',
      theme: ThemeData(
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const MainView(),
    );
  }
}