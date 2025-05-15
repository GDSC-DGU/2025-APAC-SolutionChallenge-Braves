import 'package:flutter/material.dart';
import 'image_viewer_dialog.dart';

class MissionCard extends StatelessWidget {
  final String title;
  final String date;
  final ImageProvider? image;

  const MissionCard({
    super.key,
    required this.title,
    required this.date,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        image: image != null
            ? DecorationImage(image: image!, fit: BoxFit.cover)
            : null,
      ),
    );

    if (image != null) {
      imageWidget = GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => ImageViewerDialog(
              image: image!,
              onDownload: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Image Save Feature will be implemented later.')),
                );
              },
            ),
          );
        },
        child: imageWidget,
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            imageWidget,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        date,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Completed',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 