class ForecastItem {
  const ForecastItem({
    required this.dateTime,
    required this.temperature,
    required this.condition,
    required this.iconCode,
  });

  final DateTime dateTime;
  final double temperature;
  final String condition;
  final String iconCode;

  String get iconUrl =>
      'https://openweathermap.org/img/wn/$iconCode@2x.png';

  factory ForecastItem.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weatherList = json['weather'] as List<dynamic>;
    final weatherInfo = weatherList.first as Map<String, dynamic>;

    return ForecastItem(
      dateTime: DateTime.fromMillisecondsSinceEpoch(
        (json['dt'] as num).toInt() * 1000,
      ),
      temperature: (main['temp'] as num).toDouble(),
      condition: weatherInfo['main'] as String? ?? 'Unknown',
      iconCode: weatherInfo['icon'] as String? ?? '01d',
    );
  }
}