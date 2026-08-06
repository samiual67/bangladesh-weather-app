class Weather {
  const Weather({
    required this.cityId,
    required this.cityName,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.condition,
    required this.description,
    required this.iconCode,
  });

  final int cityId;
  final String cityName;
  final String country;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final int pressure;
  final double windSpeed;
  final String condition;
  final String description;
  final String iconCode;

  String get iconUrl =>
      'https://openweathermap.org/img/wn/$iconCode@2x.png';

  factory Weather.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>?;
    final wind = json['wind'] as Map<String, dynamic>?;
    final sys = json['sys'] as Map<String, dynamic>?;
    final weatherList = json['weather'] as List<dynamic>?;

    if (main == null || wind == null || sys == null ||
        weatherList == null || weatherList.isEmpty) {
      throw const FormatException('Incomplete weather response.');
    }

    final weatherInfo = weatherList.first as Map<String, dynamic>;

    return Weather(
      cityId: (json['id'] as num).toInt(),
      cityName: json['name'] as String? ?? 'Unknown city',
      country: sys['country'] as String? ?? '',
      temperature: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num).toDouble(),
      humidity: (main['humidity'] as num).toInt(),
      pressure: (main['pressure'] as num).toInt(),
      windSpeed: (wind['speed'] as num).toDouble(),
      condition: weatherInfo['main'] as String? ?? 'Unknown',
      description: weatherInfo['description'] as String? ?? '',
      iconCode: weatherInfo['icon'] as String? ?? '01d',
    );
  }
}