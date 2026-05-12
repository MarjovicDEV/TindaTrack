import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/resources/app_copy.dart';

class ProductImagePicker extends StatelessWidget {
  const ProductImagePicker({
    required this.imagePath,
    required this.onChanged,
    super.key,
  });

  final String? imagePath;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasImage = imagePath != null && imagePath!.isNotEmpty;
    return GestureDetector(
      onTap: () => _showOptions(context),
      child: Container(
        height: 130,
        width: double.infinity,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ProductImagePreview(
                    imageValue: imagePath,
                    fit: BoxFit.cover,
                    placeholder: _placeholder(context),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: cs.surface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => onChanged(null),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.close, size: 16, color: cs.error),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final copy = AppCopy.of(context);
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, size: 32, color: cs.onSurfaceVariant),
        const SizedBox(height: 6),
        Text(copy.uploadImage, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }

  Future<void> _showOptions(BuildContext context) async {
    final copy = AppCopy.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(copy.camera),
              onTap: () {
                Navigator.pop(context);
                _pick(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(copy.gallery),
              onTap: () {
                Navigator.pop(context);
                _pick(context, ImageSource.gallery);
              },
            ),
            if (imagePath != null && imagePath!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(copy.removeImage),
                onTap: () {
                  Navigator.pop(context);
                  onChanged(null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final copy = AppCopy.of(context);
    if (!kIsWeb && source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(copy.cameraPermissionRequired),
              action: SnackBarAction(label: copy.settingsAction, onPressed: openAppSettings),
            ),
          );
        }
        return;
      }
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 60,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      final encoded = base64Encode(bytes);
      onChanged('data:image/jpeg;base64,$encoded');
    }
  }
}

class ProductImagePreview extends StatelessWidget {
  const ProductImagePreview({
    required this.imageValue,
    required this.placeholder,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String? imageValue;
  final Widget placeholder;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final value = imageValue;
    if (value == null || value.isEmpty) return placeholder;

    if (value.startsWith('data:image')) {
      try {
        final comma = value.indexOf(',');
        if (comma < 0) return placeholder;
        final bytes = base64Decode(value.substring(comma + 1));
        return Image.memory(
          bytes,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => placeholder,
        );
      } catch (_) {
        return placeholder;
      }
    }

    if (value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('blob:')) {
      return Image.network(
        value,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }

    // Legacy local file path from old app versions.
    return placeholder;
  }
}
