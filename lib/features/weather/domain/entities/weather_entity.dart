class WeatherDay {
  final String date;
  final double tempMin;
  final double tempMax;
  final String description;
  final String icon; // OWM icon code e.g. "01d"
  final int humidity;
  final double windSpeed;

  const WeatherDay({
    required this.date,
    required this.tempMin,
    required this.tempMax,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
  });

  factory WeatherDay.fromJson(Map<String, dynamic> json) => WeatherDay(
        date: json['date'] as String,
        tempMin: (json['tempMin'] as num).toDouble(),
        tempMax: (json['tempMax'] as num).toDouble(),
        description: json['description'] as String,
        icon: json['icon'] as String,
        humidity: (json['humidity'] as num).toInt(),
        windSpeed: (json['windSpeed'] as num).toDouble(),
      );

  /// OWM icon URL
  String get iconUrl =>
      'https://openweathermap.org/img/wn/$icon@2x.png';
}

class WeatherForecast {
  final String city;
  final List<WeatherDay> forecast;
  final bool isMock;

  const WeatherForecast({
    required this.city,
    required this.forecast,
    this.isMock = false,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) => WeatherForecast(
        city: json['city'] as String? ?? '',
        forecast: (json['forecast'] as List<dynamic>?)
                ?.map((e) => WeatherDay.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        isMock: json['isMock'] as bool? ?? false,
      );
}
