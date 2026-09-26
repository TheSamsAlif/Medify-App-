import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ocr_service.dart';

class OcrPage extends StatefulWidget {
  const OcrPage({super.key});

  @override
  State<OcrPage> createState() => _OcrPageState();
}

class _OcrPageState extends State<OcrPage> {
  File? selectedImage;
  String extractedText = '';
  bool isLoading = false;
  final ImagePicker picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 90,
    );

    if (image == null) return;

    setState(() {
      selectedImage = File(image.path);
      extractedText = '';
    });
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> extractText() async {
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image first'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final text = await OcrService.extractText(selectedImage!);

      setState(() {
        extractedText = text;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image OCR'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            if (selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  selectedImage!,
                  height: 250,
                  fit: BoxFit.contain,
                ),
              )
            else
              Container(
                height: 250,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('No image selected'),
              ),

            const SizedBox(height: 20),

            // Pick Image
            ElevatedButton.icon(
              onPressed: isLoading ? null : _showImageSourceActionSheet,
              icon: const Icon(Icons.image),
              label: const Text('Select Image'),
            ),

            const SizedBox(height: 10),

            // Extract Text
            ElevatedButton.icon(
              onPressed: isLoading ? null : extractText,
              icon: const Icon(Icons.text_fields),
              label: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Extract Text'),
            ),

            const SizedBox(height: 24),

            const Text(
              'Extracted Text',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                extractedText.isEmpty
                    ? 'No text extracted yet.'
                    : extractedText,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
