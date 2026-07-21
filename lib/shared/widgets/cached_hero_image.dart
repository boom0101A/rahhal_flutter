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

  /// Emoji shown on the fallback tile when there is no image. Pick one that
  /// matches the subject (🍽️ restaurant, 🏛️ landmark, ✈️ trip) so an absent
  /// photo still reads as intentional rather than broken.
  final String placeholderEmoji;

  const CachedHeroImage({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.borderRadius,
    this.placeholderEmoji = '🏛️',
  });

  @override
  Widget build(BuildContext context) {
    // تحقق من صحة الـ URL قبل المحاولة
    if (url.isEmpty ||
        (!url.startsWith('http://') && !url.startsWith('https://'))) {
      return placeholder?.call() ??
          _DefaultPlaceholder(height: height, emoji: placeholderEmoji);
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
          placeholder?.call() ??
              _DefaultPlaceholder(height: height, emoji: placeholderEmoji),
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
  final String emoji;
  const _DefaultPlaceholder({this.height, this.emoji = '🏛️'});

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
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 36)),
      ),
    );
  }
}
