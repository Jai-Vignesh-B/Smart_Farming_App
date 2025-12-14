import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../utils/market_constants.dart';
import '../services/weather_service.dart';
import '../services/chat_service.dart';
import '../providers/theme_provider.dart';
import '../models/weather_model.dart';

class CropRecommendationScreen extends StatefulWidget {
  const CropRecommendationScreen({super.key});

  @override
  State<CropRecommendationScreen> createState() => _CropRecommendationScreenState();
}

class _CropRecommendationScreenState extends State<CropRecommendationScreen> {
  String _selectedState = "Punjab"; // Default
  bool _isLoading = false;
  Weather? _weather;
  List<dynamic> _recommendations = [];
  final WeatherService _weatherService = WeatherService();
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }
  
  Locale? _currentLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLocale = context.locale;
    if (_currentLocale != newLocale) {
      _currentLocale = newLocale;
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _recommendations = [];
      _weather = null;
    });

    try {
      // 1. Fetch Weather for the State (using capital as proxy or first district)
      // For simplicity, we search query = State Name, India
      final weather = await _weatherService.fetchCurrentWeather("$_selectedState, IN");
      
      // 2. Generate Recommendations via Gemini
      final weatherSummary = "${weather.temperature}°C, ${weather.description}, Humidity: ${weather.humidity}%";
      final lang = context.locale.languageCode;
      
      final jsonStr = await _chatService.getCropRecommendations(_selectedState, weatherSummary, lang);
      
      // 3. Parse JSON
      final data = json.decode(jsonStr);
      
      if (mounted) {
        setState(() {
          _weather = weather;
          _recommendations = data['crops'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("cropToGrow".tr(), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        elevation: 0,
        backgroundColor: bgColor,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // State Dropdown
            _buildStateDropdown(isDark),
            const SizedBox(height: 20),
            
            // Weather Panel
            _buildWeatherPanel(isDark),
            const SizedBox(height: 24),
            
            // Results Area
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else if (_recommendations.isEmpty)
              Center(child: Text("No recommendations found.", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)))
            else
              Column(
                children: [
                  // Headers
                  Row(
                    children: [
                      Expanded(child: Text("recommendedCrops".tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87))),
                      const SizedBox(width: 16),
                      Expanded(child: Text("estMarketPrice".tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // List
                  ..._recommendations.map((c) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _buildCropCard(c, isDark)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildPriceCard(c, isDark)),
                          ],
                        ),
                      ),
                    )
                  ).toList(),
                ],
              )
          ],
        ),
      ),
    );
  }

  Widget _buildStateDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedState,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          items: MarketConstants.indianStates.map((s) {
            return DropdownMenuItem(
              value: s,
              child: Text(s.tr(), style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedState = val);
              _fetchData();
            }
          },
        ),
      ),
    );
  }

  Widget _buildWeatherPanel(bool isDark) {
    if (_weather == null && !_isLoading) return const SizedBox.shrink();
    if (_isLoading && _weather == null) return const SizedBox.shrink(); // Wait for data

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [Colors.blue.shade900, Colors.blue.shade800] 
            : [Colors.blue.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.cloudSun, size: 32, color: isDark ? Colors.white : Colors.blue),
              const SizedBox(width: 12),
              Text(
                "${_selectedState.tr()} ${"weather".tr()}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.blue.shade900),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_weather != null) ...[
            Text("${_weather!.temperature.toStringAsFixed(1)}°C", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            Text(_weather!.description.toUpperCase(), style: TextStyle(fontSize: 14, letterSpacing: 1, color: isDark ? Colors.white70 : Colors.grey[700])),
             const SizedBox(height: 8),
             Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Icon(LucideIcons.droplets, size: 14, color: isDark ? Colors.white60 : Colors.grey),
                 Text(" ${"humidity".tr()}: ${_weather!.humidity}%", style: TextStyle(color: isDark ? Colors.white60 : Colors.grey)),
                 const SizedBox(width: 16),
                 Icon(LucideIcons.wind, size: 14, color: isDark ? Colors.white60 : Colors.grey),
                 Text(" ${"wind".tr()}: ${_weather!.windSpeed} m/s", style: TextStyle(color: isDark ? Colors.white60 : Colors.grey)),
               ],
             )
          ]
        ],
      ),
    );
  }

  Widget _buildCropCard(dynamic crop, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sprout, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(crop['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87))),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: Text(crop['reason'] ?? '', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey[600], height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildPriceCard(dynamic crop, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.green.withOpacity(0.3) : Colors.green.shade100),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(crop['name'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.greenAccent : Colors.green.shade800), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(crop['marketPrice'] ?? 'N/A', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
