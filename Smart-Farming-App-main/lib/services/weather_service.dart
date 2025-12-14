import 'dart:convert';
import 'package:farmer_app/models/weather_model.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherService {
  static String get _apiKey => dotenv.env['WEATHER_API_KEY'] ?? "";
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<Weather> fetchCurrentWeather(String city, {String lang = 'en'}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/weather?q=$city&appid=$_apiKey&units=metric&lang=$lang'),
    );

    if (response.statusCode == 200) {
      return Weather.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load weather');
    }
  }

  Future<Weather> fetchCurrentWeatherByLocation(Position position, {String lang = 'en'}) async {
    final response = await http.get(
      Uri.parse(
          '$_baseUrl/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric&lang=$lang'),
    );

    if (response.statusCode == 200) {
      return Weather.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load weather');
    }
  }

  Future<List<WeatherForecast>> fetchForecast(String city, {String lang = 'en'}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/forecast?q=$city&appid=$_apiKey&units=metric&lang=$lang'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> list = data['list'];
      // Filter to get one forecast per day (e.g., at 12:00 PM)
      return list
          .where((item) => item['dt_txt'].toString().contains('12:00:00'))
          .map((json) => WeatherForecast.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load forecast');
    }
  }

  Future<List<WeatherForecast>> fetchForecastByLocation(Position position, {String lang = 'en'}) async {
    final response = await http.get(
      Uri.parse(
          '$_baseUrl/forecast?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric&lang=$lang'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> list = data['list'];
      return list
          .where((item) => item['dt_txt'].toString().contains('12:00:00'))
          .map((json) => WeatherForecast.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load forecast');
    }
  }

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  // Mock method to fetch past 7 days weather (Free API doesn't support history)
  Future<List<WeatherForecast>> fetchPastWeather(String city) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    final now = DateTime.now();
    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: index + 1));
      // Generate somewhat realistic data around 20-30 degrees
      double temp = 20 + (date.day % 10) + (index % 5).toDouble(); 
      return WeatherForecast(
        date: date.toIso8601String(), // Model expects String
        temp: temp, // Model expects temp
        description: index % 2 == 0 ? "Sunny" : "Partly Cloudy",
        icon: index % 2 == 0 ? "01d" : "02d", // Model expects icon
      );
    });
  }
}
