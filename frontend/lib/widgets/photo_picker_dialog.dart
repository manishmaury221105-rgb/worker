import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_colors.dart';
import 'app_image.dart';
import 'custom_text_field.dart';

class PhotoPickerDialog extends StatefulWidget {
  final String title;
  final String? currentUrl;
  final Function(String) onSaved;
  final List<Map<String, String>>? samplePresets;

  const PhotoPickerDialog({
    super.key,
    required this.title,
    this.currentUrl,
    required this.onSaved,
    this.samplePresets,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    String? currentUrl,
    required Function(String) onSaved,
    List<Map<String, String>>? samplePresets,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => PhotoPickerDialog(
        title: title,
        currentUrl: currentUrl,
        onSaved: onSaved,
        samplePresets: samplePresets,
      ),
    );
  }

  @override
  State<PhotoPickerDialog> createState() => _PhotoPickerDialogState();
}

class _PhotoPickerDialogState extends State<PhotoPickerDialog> {
  final _urlController = TextEditingController();
  final _picker = ImagePicker();
  String _selectedImage = '';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.currentUrl ?? '';
    _urlController.text = _selectedImage.startsWith('data:image') ? '' : _selectedImage;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isProcessing = true);
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (file != null) {
        final Uint8List bytes = await file.readAsBytes();
        final String ext = file.name.split('.').last.toLowerCase();
        final String mime = (ext == 'png') ? 'image/png' : 'image/jpeg';
        final String base64Data = 'data:$mime;base64,${base64Encode(bytes)}';

        setState(() {
          _selectedImage = base64Data;
          _urlController.clear();
          _isProcessing = false;
        });
      } else {
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('फोटो चुनने में समस्या (Failed to pick image): $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // DIRECT PHONE UPLOAD BUTTONS (Camera & Gallery)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'फ़ोन से फ़ोटो अपलोड करें (Choose from Phone):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Camera Button
                      if (!kIsWeb)
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt_rounded, size: 18),
                            label: const Text('कैमरा (Camera)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            onPressed: _isProcessing ? null : () => _pickImage(ImageSource.camera),
                          ),
                        ),
                      if (!kIsWeb) const SizedBox(width: 8),

                      // Gallery Button
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.photo_library_rounded, size: 18),
                          label: const Text('गैलरी (Gallery)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          onPressed: _isProcessing ? null : () => _pickImage(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_isProcessing) ...[
              const SizedBox(height: 14),
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 10),
                    Text('फोटो प्रोसेस हो रही है...', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // OR Web URL Input
            const Text(
              'या वेब URL / लिंक डालें (Or Enter Image URL):',
              style: TextStyle(fontSize: 11.5, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              label: 'Photo URL',
              hint: 'https://...',
              controller: _urlController,
              prefixIcon: Icons.link_rounded,
              onChanged: (val) {
                setState(() {
                  _selectedImage = val.trim();
                });
              },
            ),

            // Quick Samples if provided
            if (widget.samplePresets != null && widget.samplePresets!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: widget.samplePresets!.map((sample) {
                  return ActionChip(
                    avatar: const Icon(Icons.image_outlined, size: 14),
                    label: Text(sample['label'] ?? 'Sample', style: const TextStyle(fontSize: 11)),
                    onPressed: () {
                      final url = sample['url'] ?? '';
                      _urlController.text = url;
                      setState(() {
                        _selectedImage = url;
                      });
                    },
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 14),

            // Live Image Preview Box
            if (_selectedImage.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Preview (पूर्वावलोकन):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                    label: const Text('हटाएं', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                    onPressed: () {
                      setState(() {
                        _selectedImage = '';
                        _urlController.clear();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                  color: Colors.black12,
                ),
                clipBehavior: Clip.antiAlias,
                child: AppImage(
                  imageSource: _selectedImage,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('रद्द करें (Cancel)'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _selectedImage.isEmpty
              ? null
              : () {
                  widget.onSaved(_selectedImage);
                  Navigator.of(context).pop();
                },
          child: const Text('फ़ोटो सेट करें (Attach Photo)'),
        ),
      ],
    );
  }
}
