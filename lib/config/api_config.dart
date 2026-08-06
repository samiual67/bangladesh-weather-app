class ApiConfig {
  static const String baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  static const String apiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
    defaultValue: '',
  );
}