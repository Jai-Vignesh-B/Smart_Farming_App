import 'package:easy_localization/easy_localization.dart';
import 'package:farmer_app/models/weather_model.dart';
import 'package:farmer_app/providers/theme_provider.dart';
import 'package:farmer_app/screens/weather_screen.dart';
import 'package:farmer_app/services/weather_service.dart';
import 'package:farmer_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  final WeatherService _weatherService = WeatherService();
  Weather? _weather;
  bool _isLoading = true;
  String? _lastLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = context.locale.languageCode;
    if (_lastLocale != currentLocale) {
      _lastLocale = currentLocale;
      _fetchWeather();
    }
  }

  Future<void> _fetchWeather() async {
    try {
      final weather = await _weatherService.fetchCurrentWeather('Punjab', lang: context.locale.languageCode);
      if (mounted) {
        setState(() {
          _weather = weather;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false; // Mock data could be used here
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WeatherScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.mapPin, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      _weather?.cityName ?? "Locating...",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (_weather != null)
                      Image.network(
                        'https://openweathermap.org/img/wn/${_weather!.iconCode}.png',
                        width: 30,
                        height: 30,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      _weather != null ? "${_weather!.temperature.toStringAsFixed(0)}°" : "--°",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 24),

            // Stats Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat(LucideIcons.thermometer, "+22 C", "Soil Temp", Colors.orange), // Soil temp not in standard weather API, keeping partial mock/estimation
                _buildDivider(),
                _buildStat(LucideIcons.droplets, _weather?.humidity.toString() ?? "--" "%", "Humidity", Colors.blue),
                _buildDivider(),
                _buildStat(LucideIcons.wind, "${_weather?.windSpeed.toStringAsFixed(1) ?? '--'} m/s", "Wind", Colors.grey),
                _buildDivider(),
                _buildStat(LucideIcons.cloudRain, "${_weather?.rain.toStringAsFixed(1) ?? '0'} mm", "Precip", Colors.amber),
              ],
            ),

            const SizedBox(height: 20),
            
            // Solar Curve
            Container(
              height: 48,
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    top: 10,
                    child: Builder(
                      builder: (context) {
                        // Safe defaults
                        int sunrise = _weather?.sunrise ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
                        int sunset = _weather?.sunset ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
                        int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
                        
                        if (_weather == null) return CustomPaint(painter: SolarCurvePainter(0, 1, 0));

                         // Determine if night
                        bool isNight = now > sunset || now < sunrise;
                        
                        return CustomPaint(
                          painter: SolarCurvePainter(sunrise, sunset, now),
                        );
                      }
                    ),
                  ),
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Builder(
                      builder: (context) {
                        if (_weather == null) return Text("--:--", style: TextStyle(fontSize: 10, color: Colors.grey[400]));
                        int sunrise = _weather!.sunrise;
                        int sunset = _weather!.sunset;
                        int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
                        bool isNight = now > sunset || now < sunrise;
                        
                        // Left Label: Sunrise (Day) or Sunset (Night)
                        int timeToShow = isNight ? sunset : sunrise;
                        
                        return Text(
                          DateFormat('h:mm a').format(DateTime.fromMillisecondsSinceEpoch(timeToShow * 1000)),
                          style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                        );
                      }
                    ),
                  ),
                  Positioned(
                    left: 0, 
                    bottom: 12,
                    child: Builder(
                      builder: (context) {
                         if (_weather == null) return const SizedBox();
                         int sunrise = _weather!.sunrise;
                         int sunset = _weather!.sunset;
                         int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
                         bool isNight = now > sunset || now < sunrise;
                         return Text(isNight ? "Sunset" : "Sunrise", style: TextStyle(fontSize: 8, color: Colors.grey[300]));
                      }
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Builder(
                      builder: (context) {
                        if (_weather == null) return Text("--:--", style: TextStyle(fontSize: 10, color: Colors.grey[400]), textAlign: TextAlign.right);
                        int sunrise = _weather!.sunrise;
                        int sunset = _weather!.sunset;
                        int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
                        bool isNight = now > sunset || now < sunrise;
                        
                        // Right Label: Sunset (Day) or Sunrise (Night)
                        int timeToShow = isNight ? sunrise : sunset; // Ideally sunrise should be tomorrow's, but logic-wise for display we use the time digits
                        
                        return Text(
                          DateFormat('h:mm a').format(DateTime.fromMillisecondsSinceEpoch(timeToShow * 1000)),
                          textAlign: TextAlign.right, style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                        );
                      }
                    ),
                  ),
                   Positioned(
                    right: 0, 
                    bottom: 12,
                    child: Builder(
                       builder: (context) {
                         if (_weather == null) return const SizedBox();
                         int sunrise = _weather!.sunrise;
                         int sunset = _weather!.sunset;
                         int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
                         bool isNight = now > sunset || now < sunrise;
                         return Text(isNight ? "Sunrise" : "Sunset", style: TextStyle(fontSize: 8, color: Colors.grey[300]));
                      }
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // View Details Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WeatherScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text("viewForecast7Days".tr(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label, Color color) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1E293B))),
        Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.grey[500])),
      ],
    );
  }

  Widget _buildDivider() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(width: 1, height: 32, color: isDark ? Colors.white24 : Colors.grey[200]);
  }
}

class SolarCurvePainter extends CustomPainter {
  final int sunrise;
  final int sunset;
  final int current;

  SolarCurvePainter(this.sunrise, this.sunset, this.current);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Determine if it's night
    // Night is: current > sunset OR current < sunrise
    bool isNight = current > sunset || current < sunrise;

    // Draw the arc
    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width / 2, -size.height * 0.5, size.width, size.height);
    
    // Change arc color for night
    if (isNight) paint.color = Colors.indigo.withOpacity(0.2);
    canvas.drawPath(path, paint);

    // Calculate Position (t)
    double t = 0.0;
    
    if (!isNight) {
      // DAY MODE: Sunrise -> Sunset
      if (current <= sunrise) {
        t = 0.0;
      } else if (current >= sunset) {
        t = 1.0;
      } else {
        t = (current - sunrise) / (sunset - sunrise);
      }
    } else {
      // NIGHT MODE: Sunset -> Next Sunrise
      // We need to approximate 'next sunrise' or 'previous sunset' for smooth animation
      // Simplified: 
      // If current > sunset (Evening/Night), t goes from 0.0 (at sunset) to 0.5 (at midnight).
      // If current < sunrise (Early Morning), t goes from 0.5 to 1.0 (at sunrise).
      
      // Total night duration ~12 hours (43200s) usually, but better to use actual diff if we had next day sunrise.
      // For visual approximation:
      // Let's assume Night is 12 hours total.
      // Midnight is roughly Sunset + (Sunset-Sunrise)/2 ?? No.
      
      // Better approach:
      // If After Sunset: t = (current - sunset) / (86400 - (sunset - sunrise)) -- approx night duration
      
      int nightDuration = 43200; // 12 hours approx
      
      if (current > sunset) {
         // Evening: 0.0 to 0.5
         double progress = (current - sunset) / nightDuration;
         t = progress > 1.0 ? 1.0 : progress; 
      } else {
         // Morning before sunrise: 
         // We want it to end at 1.0 at sunrise.
         // Let's say it starts at 0.0 at (sunrise - 12h)
         double progress = (current - (sunrise - nightDuration)) / nightDuration;
         t = progress < 0.0 ? 0.0 : progress;
      }
    }

    // Common Bezier Math
    final p0 = Offset(0, size.height);
    final p1 = Offset(size.width / 2, -size.height * 0.5);
    final p2 = Offset(size.width, size.height);

    double x = (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * p2.dx;
    double y = (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * p2.dy;

    // Draw Icon (Sun or Moon)
    if (isNight) {
      // MOON
      // Glow
      canvas.drawCircle(Offset(x, y), 8, Paint()..color = Colors.indigo.withOpacity(0.2));
      // Crescent approximation (White Circle)
      canvas.drawCircle(Offset(x, y), 6, Paint()..color = Colors.grey.shade300);
      // Darker circle to make crescent? Too complex. Simple Grey Moon is fine.
    } else {
      // SUN
      // Glow
      canvas.drawCircle(Offset(x, y), 10, Paint()..color = Colors.orange.withOpacity(0.3));
      // Core
      canvas.drawCircle(Offset(x, y), 6, Paint()..color = Colors.orange);
    }
  }

  @override
  bool shouldRepaint(covariant SolarCurvePainter oldDelegate) {
    return oldDelegate.current != current || oldDelegate.sunrise != sunrise || oldDelegate.sunset != sunset;
  }
}
