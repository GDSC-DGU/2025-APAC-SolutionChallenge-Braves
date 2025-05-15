import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MissionCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isImageRegistered;
  final bool isCompleted;
  final String? imageUrl;
  final VoidCallback onComplete;
  final ValueChanged<XFile> onImageRegister;
  final ValueChanged<XFile>? onImageUpdate;
  final bool isProposed;

  const MissionCard({
    super.key,
    required this.title,
    required this.description,
    required this.isImageRegistered,
    required this.isCompleted,
    required this.onComplete,
    required this.onImageRegister,
    this.onImageUpdate,
    this.imageUrl,
    this.isProposed = false,
  });

  Future<void> _showImageRegisterDialog(BuildContext context) async {
    XFile? _image;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> _pickImage() async {
              final picker = ImagePicker();
              final picked = await picker.pickImage(source: ImageSource.gallery);
              if (picked != null) {
                setState(() {
                  _image = picked;
                });
              }
            }
            return AlertDialog(
              title: const Text('Mission Image Register'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _image != null
                      ? Image.file(File(_image!.path), height: 120)
                      : Container(
                          height: 120,
                          color: Colors.grey[200],
                          child: const Center(child: Text('Image Select')),
                        ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text('Image Select'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _image != null
                      ? () {
                          Navigator.pop(context, _image);
                        }
                      : null,
                  child: const Text('Register'),
                ),
              ],
            );
          },
        );
      },
    ).then((result) {
      if (result is XFile) {
        onImageRegister(result);
      }
    });
  }

  Future<void> _showImageUpdateDialog(BuildContext context) async {
    XFile? _image;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> _pickImage() async {
              final picker = ImagePicker();
              final picked = await picker.pickImage(source: ImageSource.gallery);
              if (picked != null) {
                setState(() {
                  _image = picked;
                });
              }
            }
            return AlertDialog(
              title: const Text('Mission Image Update'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _image != null
                      ? Image.file(File(_image!.path), height: 120)
                      : Container(
                          height: 120,
                          color: Colors.grey[200],
                          child: const Center(child: Text('Image Select')),
                        ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text('Image Select'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _image != null
                      ? () {
                          Navigator.pop(context, _image);
                        }
                      : null,
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    ).then((result) {
      if (result is XFile && onImageUpdate != null) {
        onImageUpdate!(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                if (isProposed)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Proposed Mission', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 140,
              child: SingleChildScrollView(
                child: Text(description, style: const TextStyle(fontSize: 14, color: Colors.black87)),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: isCompleted
                  ? ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Completed Mission'),
                    )
                  : isImageRegistered
                      ? Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _showImageUpdateDialog(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                  side: const BorderSide(color: Colors.orange),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Image Update'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: onComplete,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1976D2),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Complete Mission'),
                              ),
                            ),
                          ],
                        )
                      : ElevatedButton(
                          onPressed: () => _showImageRegisterDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Image Register'),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}