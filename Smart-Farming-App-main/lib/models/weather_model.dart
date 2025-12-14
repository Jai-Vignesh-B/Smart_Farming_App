class Weather {
  final String cityName;
  final double temperature;
  final String description;
  final String iconCode;
  final double windSpeed;
  final int humidity;
  final double rain;
  final int sunrise;
  final int sunset;
  final List<WeatherForecast> forecast;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.description,
    required this.iconCode,
    required this.windSpeed,
    required this.humidity,
    this.rain = 0.0,
    this.sunrise = 0,
    this.sunset = 0,
    this.forecast = const [],
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      cityName: json['name'] ?? '',
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'] ?? '',
      iconCode: json['weather'][0]['icon'] ?? '',
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      humidity: json['main']['humidity'] as int,
      rain: (json['rain'] != null && json['rain']['1h'] != null) 
          ? (json['rain']['1h'] as num).toDouble() 
          : 0.0,
      sunrise: json['sys']['sunrise'] as int,
      sunset: json['sys']['sunset'] as int,
    );
  }
}

class WeatherForecast {
  final String date;
  final double temp;
  final String description;
  final String icon;

  WeatherForecast({
    required this.date,
    required this.temp,
    required this.description,
    required this.icon,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      date: json['dt_txt'] ?? '',
      temp: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'] ?? '',
      icon: json['weather'][0]['icon'] ?? '',
    );
  }
}
