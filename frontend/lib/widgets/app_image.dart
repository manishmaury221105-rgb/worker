import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class AppImage extends StatelessWidget {
  final String? imageSource;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppImage({
    super.key,
    required this.imageSource,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = _buildImageWidget(context);
    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _buildImageWidget(BuildContext context) {
    if (imageSource == null || imageSource!.trim().isEmpty) {
      return _buildPlaceholder();
    }

    final src = imageSource!.trim();

    // Base64 Data URI or raw base64
    if (src.startsWith('data:image') || _isBase64(src)) {
      try {
        final base64String = src.contains(',') ? src.split(',').last : src;
        final Uint8List bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildErrorWidget(),
        );
      } catch (_) {
        return _buildErrorWidget();
      }
    }

    // Network HTTP/HTTPS
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(
        src,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.black12,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildErrorWidget(),
      );
    }

    return _buildErrorWidget();
  }

  bool _isBase64(String str) {
    if (str.length < 50) return false;
    // Quick heuristic for base64
    final clean = str.replaceAll('\n', '').replaceAll('\r', '').replaceAll(' ', '');
    return RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(clean);
  }

  Widget _buildPlaceholder() {
    return placeholder ??
        Container(
          width: width,
          height: height,
          color: Colors.grey.withOpacity(0.15),
          child: const Icon(Icons.image_outlined, color: Colors.grey, size: 28),
        );
  }

  Widget _buildErrorWidget() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.red.withOpacity(0.08),
          child: const Center(
            child: Icon(Icons.broken_image_outlined, color: Colors.redAccent, size: 26),
          ),
        );
  }
}
