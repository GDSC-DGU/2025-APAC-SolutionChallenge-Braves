import 'package:flutter/material.dart';

class NewTripButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const NewTripButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF56BC6C),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFB8B741), width: 2),
          ),
          elevation: 2,
          shadowColor: const Color(0xFFB8B741),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.white),
            SizedBox(width: 8),
            Text('Start a new journey', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
} 