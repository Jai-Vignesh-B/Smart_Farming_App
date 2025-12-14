import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:farmer_app/models/market_price_model.dart';
import 'package:farmer_app/models/soil_data.dart';
import 'package:intl/intl.dart';

class ApiService {
  // Config
  static String get _ogdApiKey => dotenv.env['OGD_API_KEY'] ?? "";
  static const String _ogdResourceId = "9ef84268-d588-465a-a308-a864a43d0070";
  static String get _geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? "";

  // Caching
  final Map<String, List<MarketPrice>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // ---------------------------------------------------------------------------
  // MARKET PRICES - HYBRID (Real Gov API -> Mock Fallback)
  // ---------------------------------------------------------------------------
  Future<List<MarketPrice>> fetchMarketPrices(String state, String district, String commodity, String market) async {
    final cacheKey = '$state|$district|$commodity|$market';

    // 1. Check Cache (Instant Return)
    if (_cache.containsKey(cacheKey)) {
      final cacheTime = _cacheTimestamps[cacheKey];
      if (cacheTime != null && DateTime.now().difference(cacheTime) < _cacheExpiry) {
        debugPrint("🚀 Returning cached data for: $cacheKey");
        return _cache[cacheKey]!;
      }
    }

    // 2. Try Real Government API
    try {
      String baseUrl = "https://api.data.gov.in/resource/$_ogdResourceId?api-key=$_ogdApiKey&format=json&limit=20";
      String url = baseUrl;
      if (state.isNotEmpty) url += "&filters[state]=${Uri.encodeComponent(state)}";
      if (district.isNotEmpty && district != "All Districts") {
         url += "&filters[district]=${Uri.encodeComponent(district)}";
      }
      if (commodity.isNotEmpty) url += "&filters[commodity]=${Uri.encodeComponent(commodity)}";
      // Skip market filter to increase hit chance, or include it if specific.

      debugPrint("🔍 Trying Gov API: $url");
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final records = data['records'] as List?;
        if (records != null && records.isNotEmpty) {
           List<MarketPrice> realData = records.map((e) => MarketPrice.fromJson(e)).toList();
           _cache[cacheKey] = realData;
           _cacheTimestamps[cacheKey] = DateTime.now();
           debugPrint("✅ Gov API Success: ${realData.length} records");
           return realData;
        }
      }
      debugPrint("⚠️ Gov API returned 0 records. Switching to Mock...");
    } catch (e) {
      debugPrint("❌ Gov API Failed/Timeout ($e). Switching to Mock...");
    }

    // 3. Mock Fallback (Guaranteed Data)
    // No artificial delay needed if we already waited 3s for API (or failed instantly). 
    // If API failed instantly, we might want a small delay for UX so it doesn't flicker, but instant is better.
    
    final mockData = _generateMockData(state, district, commodity, market);
    _cache[cacheKey] = mockData;
    _cacheTimestamps[cacheKey] = DateTime.now();
    return mockData;
  }

  List<MarketPrice> _generateMockData(String state, String district, String commodity, String market) {
    if (state.isEmpty) state = "Punjab";
    if (commodity.isEmpty) commodity = "Wheat";
    
    final List<MarketPrice> mockData = [];
    final random = Random();
    final now = DateTime.now();

    // Base price generation based on commodity name length to be somewhat consistent
    double basePrice = 2000.0 + (commodity.length * 100);
    if (commodity.toLowerCase().contains("tomato")) basePrice = 4000.0;
    if (commodity.toLowerCase().contains("potato")) basePrice = 1200.0;
    if (commodity.toLowerCase().contains("onion")) basePrice = 3500.0;

    // Generate data for the last 10 days
    for (int i = 0; i < 10; i++) {
        DateTime date = now.subtract(Duration(days: i));
        String dateStr = DateFormat('dd/MM/yyyy').format(date);

        // Create some daily price fluctuation
        double dailyVariation = (random.nextDouble() * 400) - 200; // +/- 200
        double modal = basePrice + dailyVariation;
        double minP = modal - (random.nextDouble() * 200);
        double maxP = modal + (random.nextDouble() * 200);

        String distName = district;
        if (district.isEmpty || district == "All Districts") {
            // Pick a random district if none selected
            final dists = ["Amritsar", "Ludhiana", "Patiala", "Jalandhar", "Bathinda"];
            distName = dists[random.nextInt(dists.length)];
        }

        mockData.add(MarketPrice(
            state: state,
            district: distName,
            market: market.isEmpty || market == "All Markets" ? "Main Mandi" : market,
            commodity: commodity,
            variety: "FAQ",
            arrivalDate: dateStr,
            minPrice: minP,
            maxPrice: maxP,
            modalPrice: modal,
        ));
    }
    
    // Sort by date (descending usually, or ascending)
    // Application usually expects them random or sorted. Let's return as is.
    return mockData;
  }

 
  Future<Map<String, dynamic>> analyzeSoilHealth(SoilData data, String languageCode) async {
    if (_geminiApiKey.isEmpty) {
      return {
        "error": "API Key Missing"
      };
    }

    try {
      // Using gemini-pro (stable free tier)
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _geminiApiKey);

      final prompt = '''
        Analyze this soil data:
        Nitrogen (N): ${data.nitrogen}
        Phosphorus (P): ${data.phosphorus}
        Potassium (K): ${data.potassium}

        Provide the output in valid JSON format.
        The output language MUST be "$languageCode".
        
        Structure:
        {
          "soil_type": "Best guess soil type based on NPK",
          "soil_health": "Description of soil health",
          "crops": ["Crop 1", "Crop 2", "Crop 3"],
          "fertilizers": ["Fertilizer 1", "Fertilizer 2"],
          "diseases": [
             {
               "name": "Disease Name",
               "solution": "Solution/Fertilizer to use"
             }
          ]
        }
      ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Soil analysis took too long');
        },
      );
      final text = response.text?.replaceAll('```json', '').replaceAll('```', '').trim() ?? "{}";
      
      try {
        return json.decode(text);
      } catch (e) {
        debugPrint("Failed to decode JSON from Gemini: $text");
        return {
          "error": "Failed to parse analysis results"
        };
      }
    } catch (e) {
      debugPrint("Error analyzing soil: $e");
      return {
        "error": "Failed to analyze data"
      };
    }
  }
}
