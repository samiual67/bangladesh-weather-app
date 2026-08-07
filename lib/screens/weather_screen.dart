import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../data/bd_locations.dart';
import '../main.dart';
import '../models/forecast.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _service = const WeatherService();
  final _searchController = TextEditingController();

  List<String> _suggestions = [];
  Future<Weather>? _weatherFuture;
  Future<List<ForecastItem>>? _forecastFuture;
  bool _locating = false;

  void _onSearchChanged(String query) {
    setState(() {
      _suggestions = BDLocations.search(query);
    });
  }

  void _selectDistrict(String district) {
    _searchController.text = district;
    setState(() {
      _suggestions = [];
      _weatherFuture = _service.fetchByCityName(district);
      _forecastFuture = _service.fetchForecastByCityName(district);
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const WeatherException('Location service is off. Enable GPS.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw const WeatherException('Location permission denied.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw const WeatherException(
          'Location permission permanently denied.',
        );
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _searchController.clear();
        _weatherFuture = _service.fetchByCoordinates(
          position.latitude,
          position.longitude,
        );
        _forecastFuture = _service.fetchForecastByCoordinates(
          position.latitude,
          position.longitude,
        );
      });
    } catch (e) {
      setState(() {
        _weatherFuture = Future.error(e);
        _forecastFuture = null;
      });
    } finally {
      setState(() => _locating = false);
    }
  }

  void _toggleDarkMode(bool isDark) {
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Bangladesh Weather'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => _toggleDarkMode(!isDark),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Search district',
                hintText: 'e.g. Bogra, Dhaka, Sylhet',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _suggestions = []);
                        },
                      )
                    : null,
              ),
            ),
            if (_suggestions.isNotEmpty)
              Card(
                margin: const EdgeInsets.only(top: 4),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final district = _suggestions[index];
                    return ListTile(
                      leading: const Icon(Icons.location_city),
                      title: Text(district),
                      onTap: () => _selectDistrict(district),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _locating ? null : _useMyLocation,
              icon: _locating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(_locating ? 'Locating...' : 'Use My Location'),
            ),
            const SizedBox(height: 24),
            if (_weatherFuture == null)
              const _InitialMessage()
            else
              FutureBuilder<Weather>(
                future: _weatherFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Icon(Icons.cloud_sync_rounded, size: 48),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return _ErrorCard(message: snapshot.error.toString());
                  }
                  final weather = snapshot.data;
                  if (weather == null) {
                    return const _ErrorCard(message: 'No data available.');
                  }
                  return _WeatherCard(weather: weather);
                },
              ),
            const SizedBox(height: 20),
            if (_forecastFuture != null)
              FutureBuilder<List<ForecastItem>>(
                future: _forecastFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Icon(Icons.cloud_sync_rounded, size: 32),
                      ),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  return _ForecastRow(items: snapshot.data!);
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Grid'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Location'),
        ],
      ),
    );
  }
}

class _InitialMessage extends StatelessWidget {
  const _InitialMessage();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.wb_cloudy_outlined, size: 64),
            SizedBox(height: 12),
            Text(
              'Search a district or use your location.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastRow extends StatelessWidget {
  const _ForecastRow({required this.items});

  final List<ForecastItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final hour = item.dateTime.hour;
          final label = hour == 0
              ? '12 am'
              : hour < 12
                  ? '$hour am'
                  : hour == 12
                      ? '12 pm'
                      : '${hour - 12} pm';

          return Container(
            width: 78,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.condition,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Image.network(
                  item.iconUrl,
                  width: 34,
                  height: 34,
                  errorBuilder: (_, __, ___) => const Icon(Icons.cloud),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.temperature.toStringAsFixed(0)}°',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  maxLines: 1,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({required this.weather});

  final Weather weather;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Icon(
            _iconForCondition(weather.condition),
            size: 100,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            '${weather.temperature.toStringAsFixed(0)}°',
            style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${weather.cityName.toUpperCase()}, ${weather.country}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          Text(
            weather.description.toUpperCase(),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  value: '${weather.windSpeed.toStringAsFixed(0)}',
                  label: 'Wind Flow',
                  icon: Icons.air,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricBox(
                  value: '${weather.pressure}',
                  label: 'Pressure',
                  icon: Icons.speed,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricBox(
                  value: '${weather.humidity}%',
                  label: 'Humidity',
                  icon: Icons.water_drop,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconForCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny_rounded;
      case 'clouds':
        return Icons.wb_cloudy_rounded;
      case 'rain':
      case 'drizzle':
        return Icons.grain_rounded;
      case 'thunderstorm':
        return Icons.thunderstorm_rounded;
      case 'snow':
        return Icons.ac_unit_rounded;
      default:
        return Icons.cloud_rounded;
    }
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}