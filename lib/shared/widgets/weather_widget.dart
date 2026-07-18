import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/weather_service.dart';
import '../../core/di/injection.dart';

class WeatherWidget extends StatefulWidget {
  final String city;
  final String? countryCode;

  const WeatherWidget({super.key, required this.city, this.countryCode});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  WeatherData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final data = await sl<WeatherService>()
        .getWeather(widget.city, countryCode: widget.countryCode);
    if (mounted) setState(() { _data = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 24, height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentAmber),
      );
    }
    if (_data == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_data!.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_data!.temp}°',
                style: AppTextStyles.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _data!.description,
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💧 ${_data!.humidity}%',
                  style: AppTextStyles.labelSmall.copyWith(color: Colors.white70)),
              Text('🌬️ ${_data!.windSpeed.toStringAsFixed(1)} m/s',
                  style: AppTextStyles.labelSmall.copyWith(color: Colors.white70)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
