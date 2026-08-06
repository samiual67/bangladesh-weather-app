import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/weather.dart';

class WeatherException implements Exception {
  const WeatherException(this.message);
  final String message;

  @override
  String toString() => message;
}

class WeatherService {
  const WeatherService();

  Future<Weather> fetchByCityName(String cityName) async {
    if (ApiConfig.apiKey.isEmpty) {
      throw const WeatherException(
        'API key is missing. Run the app with OPENWEATHER_API_KEY.',
      );
    }

    final uri = Uri.parse(ApiConfig.baseUrl).replace(
      queryParameters: {
        'q': '$cityName,BD',
        'appid': ApiConfig.apiKey,
        'units': 'metric',
        'lang': 'en',
      },
    );

    return _fetchAndParse(uri);
  }

  Future<Weather> fetchByCoordinates(double lat, double lon) async {
    if (ApiConfig.apiKey.isEmpty) {
      throw const WeatherException(
        'API key is missing. Run the app with OPENWEATHER_API_KEY.',
      );
    }

    final uri = Uri.parse(ApiConfig.baseUrl).replace(
      queryParameters: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'appid': ApiConfig.apiKey,
        'units': 'metric',
        'lang': 'en',
      },
    );

    return _fetchAndParse(uri);
  }

  Future<Weather> _fetchAndParse(Uri uri) async {
    try {
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Weather.fromJson(json);
      }

      if (response.statusCode == 401) {
        throw const WeatherException('Invalid or inactive API key.');
      }

      if (response.statusCode == 404) {
        throw const WeatherException('No weather found for this location.');
      }

      if (response.statusCode == 429) {
        throw const WeatherException('API request limit reached. Try later.');
      }

      throw WeatherException(
        'OpenWeather returned status ${response.statusCode}.',
      );
    } on TimeoutException {
      throw const WeatherException('The request timed out. Try again.');
    } on FormatException {
      throw const WeatherException('The weather response was not valid.');
    } on WeatherException {
      rethrow;
    } catch (_) {
      throw const WeatherException(
        'Unable to connect. Check the internet connection.',
      );
    }
  }
}