import 'package:flutter/material.dart';

class ImageViewerDialog extends StatelessWidget {
  final ImageProvider image;
  final VoidCallback onDownload;

  const ImageViewerDialog({
    super.key,
    required this.image,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: Image(image: image),
            ),
          ),
          Positioned(
            right: 16,
            top: 32,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.download),
                label: const Text('이미지 저장'),
                onPressed: onDownload,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 