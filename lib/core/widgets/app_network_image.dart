import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_config.dart';

class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? color;
  final IconData defaultFallbackIcon;
  final double fallbackIconSize;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.color,
    this.defaultFallbackIcon = Icons.image_outlined,
    this.fallbackIconSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final rawUrl = imageUrl?.trim() ?? '';
    if (rawUrl.isEmpty || rawUrl == 'null' || rawUrl == 'undefined') {
      return _buildFallback();
    }

    Widget content;

    // 1. Base64 Data URI
    if (rawUrl.startsWith('data:image/')) {
      try {
        final commaIdx = rawUrl.indexOf(',');
        if (commaIdx != -1) {
          final base64Str = rawUrl.substring(commaIdx + 1);
          final bytes = base64Decode(base64Str);
          content = Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            color: color,
            errorBuilder: (_, __, ___) => _buildFallback(),
          );
        } else {
          content = _buildFallback();
        }
      } catch (_) {
        content = _buildFallback();
      }
    }
    // 2. SVG Image
    else if (rawUrl.toLowerCase().endsWith('.svg') || rawUrl.toLowerCase().contains('.svg?')) {
      final finalUrl = AppConfig.normalizeImageUrl(rawUrl);
      if (finalUrl.isEmpty) {
        content = _buildFallback();
      } else {
        content = SvgPicture.network(
          finalUrl,
          width: width,
          height: height,
          fit: fit,
          colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
          placeholderBuilder: (_) => _buildPlaceholder(),
          errorBuilder: (_, __, ___) => _buildFallback(),
        );
      }
    }
    // 3. Regular Raster Image (PNG, JPG, WebP, etc.)
    else {
      final finalUrl = AppConfig.normalizeImageUrl(rawUrl);
      if (finalUrl.isEmpty) {
        content = _buildFallback();
      } else {
        content = CachedNetworkImage(
          imageUrl: finalUrl,
          width: width,
          height: height,
          fit: fit,
          color: color,
          fadeInDuration: const Duration(milliseconds: 100),
          fadeOutDuration: const Duration(milliseconds: 100),
          placeholder: (_, __) => _buildPlaceholder(),
          errorWidget: (_, __, ___) => _buildFallback(),
        );
      }
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    return content;
  }

  Widget _buildPlaceholder() {
    if (placeholder != null) return placeholder!;
    return Container(
      width: width,
      height: height,
      color: Colors.grey.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: const Color(0xFF16A34A).withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    if (errorWidget != null) return errorWidget!;
    return Container(
      width: width,
      height: height,
      color: Colors.grey.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Icon(
        defaultFallbackIcon,
        size: fallbackIconSize,
        color: const Color(0xFF94A3B8),
      ),
    );
  }
}
