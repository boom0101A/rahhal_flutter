import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/weather_entity.dart';
import '../../data/weather_repository.dart';

/// Banner صغير يعرض توقعات الطقس للأيام القادمة
/// يُستخدم في أعلى ItineraryTab
class WeatherBanner extends StatefulWidget {
  final double? lat;
  final double? lon;
  final String lang;

  const WeatherBanner({
    super.key,
    this.lat,
    this.lon,
    this.lang = 'en',
  });

  @override
  State<WeatherBanner> createState() => _WeatherBannerState();
}

class _WeatherBannerState extends State<WeatherBanner> {
  WeatherForecast? _forecast;
  bool _loading = true;
  bool _noKey = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (widget.lat == null || widget.lon == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final repo = sl<WeatherRepository>();
      final result = await repo.getForecast(
        lat: widget.lat!,
        lon: widget.lon!,
        lang: widget.lang,
      );
      if (mounted) setState(() { _forecast = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _noKey = e.toString().contains('501'); });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lat == null || widget.lon == null) return const SizedBox.shrink();
    if (_loading) return _buildSkeleton();
    if (_noKey || _forecast == null || _forecast!.forecast.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildBanner(context);
  }

  Widget _buildSkeleton() {
    return Container(
      height: 90,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.adaptiveBgCard(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    // The banner used a fixed navy gradient, which turned into a near-black
    // slab on the light theme's white background. Give light mode a pale sky
    // gradient with dark text instead.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onBannerFaint =
        isDark ? Colors.white54 : const Color(0xFF5A7A94); // captions / icons

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1A3A5C).withValues(alpha: 0.85),
                  const Color(0xFF0D2137).withValues(alpha: 0.85),
                ]
              : [
                  const Color(0xFFE8F4FD).withValues(alpha: 0.95),
                  const Color(0xFFD0EAF8).withValues(alpha: 0.95),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFF1A3A5C).withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_outlined, size: 14, color: onBannerFaint),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _forecast!.city.isNotEmpty
                      ? '${_forecast!.city} — ${AppStrings.of(context).weatherForecast}'
                      : AppStrings.of(context).weatherForecast,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: onBannerFaint,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (_forecast!.isMock) ...[
                Tooltip(
                  message: AppStrings.of(context).weatherApproximate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 11, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(
                          AppStrings.of(context).weatherSimulatedBadge,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.amber,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _forecast!.forecast.length,
              itemBuilder: (_, i) =>
                  _WeatherDayChip(day: _forecast!.forecast[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherDayChip extends StatelessWidget {
  final WeatherDay day;

  const _WeatherDayChip({required this.day});

  @override
  Widget build(BuildContext context) {
    // Same light/dark treatment as the banner this chip sits on.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onBannerStrong = isDark ? Colors.white : const Color(0xFF102A43);
    final onBannerMuted = isDark ? Colors.white60 : const Color(0xFF41627E);

    // Parse date
    final parts = day.date.split('-');
    final dt = parts.length == 3
        ? DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]))
        : null;
    final dayLabel = dt != null
        ? _shortDay(dt.weekday, context)
        : day.date.substring(5); // MM-DD

    return Container(
      margin: const EdgeInsetsDirectional.only(end: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFF1A3A5C).withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dayLabel,
            style: AppTextStyles.labelSmall.copyWith(
              color: onBannerMuted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          // Weather icon from OWM. CachedNetworkImage (not Image.network) so
          // the horizontal list doesn't re-fetch the same handful of icons
          // every time a chip scrolls back into view.
          CachedNetworkImage(
            imageUrl: day.iconUrl,
            width: 28,
            height: 28,
            // A spinner per 28px icon would flicker; keep the space reserved.
            placeholder: (_, __) => const SizedBox(width: 28, height: 28),
            errorWidget: (_, __, ___) =>
                const Icon(Icons.wb_sunny_rounded, size: 22, color: Colors.amber),
          ),
          const SizedBox(height: 2),
          Text(
            '${day.tempMax.toStringAsFixed(0)}° / ${day.tempMin.toStringAsFixed(0)}°',
            style: AppTextStyles.labelSmall.copyWith(
              color: onBannerStrong,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Weekday abbreviation in the active language. DateTime.weekday is
  /// 1 = Monday … 7 = Sunday.
  String _shortDay(int weekday, BuildContext context) {
    const arDays = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    const enDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final idx = (weekday - 1).clamp(0, 6);
    return AppStrings.of(context).languageCode == 'en' ? enDays[idx] : arDays[idx];
  }
}
