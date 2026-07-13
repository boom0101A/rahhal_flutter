import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import 'shimmer_loader.dart';

class CachedHeroImage extends StatelessWidget {
  final String url;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Widget Function()? placeholder;
  final BorderRadius? borderRadius;

  const CachedHeroImage({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // تحقق من صحة الـ URL قبل المحاولة
    if (url.isEmpty ||
        (!url.startsWith('http://') && !url.startsWith('https://'))) {
      return placeholder?.call() ?? _DefaultPlaceholder(height: height);
    }

    Widget image = CachedNetworkImage(
      imageUrl: url,
      height: height,
      width: width ?? double.infinity,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
      // Shimmer أثناء التحميل
      placeholder: (context, url) => ShimmerBox(
        height: height ?? 160,
        borderRadius: borderRadius != null ? BorderRadius.zero : BorderRadius.circular(12),
      ),
      // Placeholder عند الخطأ
      errorWidget: (context, url, error) =>
          placeholder?.call() ?? _DefaultPlaceholder(height: height),
      // Cache لمدة 7 أيام
      maxHeightDiskCache: 800,
      maxWidthDiskCache: 1200,
    ).animate().fadeIn(duration: 300.ms);

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

class _DefaultPlaceholder extends StatelessWidget {
  final double? height;
  const _DefaultPlaceholder({this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 160,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentAmber.withValues(alpha: 0.15),
            AppColors.accentTurquoise.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏛️', style: TextStyle(fontSize: 36)),
            SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
