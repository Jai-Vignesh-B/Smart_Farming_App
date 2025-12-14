import 'package:easy_localization/easy_localization.dart';
import 'package:farmer_app/models/weather_model.dart';
import 'package:farmer_app/providers/theme_provider.dart';
import 'package:farmer_app/services/weather_service.dart';
import 'package:farmer_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  final TextEditingController _searchController = TextEditingController();
  Weather? _currentWeather;
  List<WeatherForecast> _forecast = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _lastLocale;
  String _currentCity = 'Punjab';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = context.locale.languageCode;
    if (_lastLocale != currentLocale) {
      _lastLocale = currentLocale;
      _fetchWeather(_currentCity);
    }
  }

  Future<void> _fetchWeather(String city) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _currentCity = city;
    });

    try {
      final lang = context.locale.languageCode;
      final weather = await _weatherService.fetchCurrentWeather(city, lang: lang);
      final forecast = await _weatherService.fetchForecast(city, lang: lang);
      setState(() {
        _currentWeather = weather;
        _forecast = forecast;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "${'couldNotFetchWeather'.tr()} $city";
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchWeatherByLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final lang = context.locale.languageCode;
      final position = await _weatherService.getCurrentLocation();
      final weather = await _weatherService.fetchCurrentWeatherByLocation(position, lang: lang);
      final forecast = await _weatherService.fetchForecastByLocation(position, lang: lang);
      setState(() {
        _currentWeather = weather;
        _forecast = forecast;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('weather'.tr(), style: TextStyle(color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _fetchWeatherByLocation,
            color: textColor,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'searchCity'.tr(),
                hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.grey),
                suffixIcon: IconButton(
                  icon: Icon(Icons.arrow_forward, color: AppColors.primary),
                  onPressed: () {
                    if (_searchController.text.isNotEmpty) {
                      _fetchWeather(_searchController.text);
                    }
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _fetchWeather(value);
                }
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage, style: TextStyle(color: textColor)))
                    : _currentWeather == null
                        ? Center(child: Text('noData'.tr(), style: TextStyle(color: textColor)))
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildCurrentWeather(),
                                const SizedBox(height: 20),
                                _buildForecastList(isDark, textColor),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeather() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _currentWeather!.cityName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Image.network(
            'https://openweathermap.org/img/wn/${_currentWeather!.iconCode}@2x.png',
            height: 80,
            width: 80,
          ),
          Text(
            '${_currentWeather!.temperature.toStringAsFixed(1)}°C',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            _currentWeather!.description.toUpperCase(),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherDetail(
                  Icons.water_drop, '${_currentWeather!.humidity}%', 'humidity'.tr()),
              _buildWeatherDetail(Icons.air,
                  '${_currentWeather!.windSpeed} m/s', 'wind'.tr()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildForecastList(bool isDark, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "viewForecast7Days".tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _forecast.length,
          itemBuilder: (context, index) {
            final item = _forecast[index];
            DateTime date;
            try {
              date = DateTime.parse(item.date);
            } catch (e) {
              date = DateTime.now();
            }
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)
              ),
              child: ListTile(
                leading: Image.network(
                  'https://openweathermap.org/img/wn/${item.icon}.png',
                  width: 50,
                  height: 50,
                  errorBuilder: (c,e,s) => const Icon(Icons.wb_sunny_outlined, color: Colors.orange), 
                ),
                title: Text(
                  DateFormat('EEEE, MMM d').format(date), 
                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                ),
                subtitle: Text(item.description, style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600])),
                trailing: Text(
                  '${item.temp.toStringAsFixed(1)}°C',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
