import 'dart:io';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Disease detection result from Gemini AI
class DiseaseDetectionResult {
  final String plantName;
  final String diseaseName;
  final double confidence;

  DiseaseDetectionResult({
    required this.plantName,
    required this.diseaseName,
    required this.confidence,
  });

  factory DiseaseDetectionResult.fromJson(Map<String, dynamic> json) {
    return DiseaseDetectionResult(
      plantName: json['plantName'] as String? ?? 'Unknown',
      diseaseName: json['diseaseName'] as String? ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Disease remedy information from Gemini AI
class DiseaseRemedy {
  final String plantName;
  final String diseaseName;
  final String whyItCame;          // Why this disease occurred
  final String howItCame;          // How this disease spreads/develops
  final String preventionNow;      // How to prevent now (current treatment)
  final String preventionFuture;   // How to prevent in future
  final List<String> recommendedFertilizers; // Fertilizers to reduce disease

  DiseaseRemedy({
    required this.plantName,
    required this.diseaseName,
    required this.whyItCame,
    required this.howItCame,
    required this.preventionNow,
    required this.preventionFuture,
    required this.recommendedFertilizers,
  });

  factory DiseaseRemedy.fromJson(Map<String, dynamic> json) {
    return DiseaseRemedy(
      plantName: json['plantName'] as String? ?? 'Unknown',
      diseaseName: json['diseaseName'] as String? ?? 'Unknown',
      whyItCame: json['whyItCame'] as String? ?? 'No information available',
      howItCame: json['howItCame'] as String? ?? 'No information available',
      preventionNow: json['preventionNow'] as String? ?? 'No information available',
      preventionFuture: json['preventionFuture'] as String? ?? 'No information available',
      recommendedFertilizers: (json['recommendedFertilizers'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

/// Service for Gemini AI-powered disease detection
class GeminiDiseaseService {
  late final GenerativeModel _model;
  
  GeminiDiseaseService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }
    
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
  }

  /// Detect disease from plant image with multi-language support
  /// 
  /// [imageFile] - The plant image file to analyze
  /// [languageCode] - Language code for response (en, hi, pa)
  Future<DiseaseDetectionResult> detectDiseaseFromImage(
    File imageFile,
    String languageCode,
  ) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      
      // Map language codes to language names
      final languageMap = {
        'en': 'English',
        'hi': 'Hindi (हिंदी)',
        'pa': 'Punjabi (ਪੰਜਾਬੀ)',
        'ta': 'Tamil (தமிழ்)',
      };
      
      final language = languageMap[languageCode] ?? 'English';
      
      final prompt = '''
Identify the plant and the specific disease affecting it from this image.
If the plant appears healthy, respond with disease name as "Healthy".

IMPORTANT: You MUST respond ONLY in $language language. Do NOT use English or any other language.
All field values must be in $language language.

Return a JSON object with the following structure:
{
  "plantName": "name of the plant in $language",
  "diseaseName": "name of the disease in $language",
  "confidence": 0.85
}
''';

      final content = [
        Content.multi([
          DataPart('image/jpeg', imageBytes),
          TextPart(prompt),
        ])
      ];

      final response = await _model.generateContent(
        content,
        generationConfig: GenerationConfig(
          temperature: 0.4,
          topK: 32,
          topP: 1,
          maxOutputTokens: 2048,
        ),
      );

      final text = response.text;
      if (text == null || text.isEmpty) {
        throw Exception('No response from Gemini AI');
      }

      // Extract JSON from response (handle markdown code blocks)
      String jsonString = text.trim();
      if (jsonString.startsWith('```json')) {
        jsonString = jsonString.substring(7);
      } else if (jsonString.startsWith('```')) {
        jsonString = jsonString.substring(3);
      }
      if (jsonString.endsWith('```')) {
        jsonString = jsonString.substring(0, jsonString.length - 3);
      }
      jsonString = jsonString.trim();

      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return DiseaseDetectionResult.fromJson(jsonData);
    } catch (e) {
      print('Error detecting disease: $e');
      // Return fallback result
      return DiseaseDetectionResult(
        plantName: 'Unknown',
        diseaseName: 'Analysis Failed',
        confidence: 0.0,
      );
    }
  }

  /// Get remedy and preventive measures for a detected disease
  /// 
  /// [plantName] - Name of the plant
  /// [diseaseName] - Name of the disease
  /// [languageCode] - Language code for response (en, hi, pa)
  Future<DiseaseRemedy> getRemedyForDisease(
    String plantName,
    String diseaseName,
    String languageCode,
  ) async {
    try {
      // Map language codes to language names
      final languageMap = {
        'en': 'English',
        'hi': 'Hindi (हिंदी)',
        'pa': 'Punjabi (ਪੰਜਾਬੀ)',
        'ta': 'Tamil (தமிழ்)',
      };
      
      final language = languageMap[languageCode] ?? 'English';
      
      final prompt = '''
The plant is "$plantName" and the disease is "$diseaseName".

IMPORTANT: You MUST provide ALL information ONLY in $language language. Do NOT use English or any other language except $language.
Provide BRIEF, CONCISE disease information. Keep each answer to 1-2 sentences maximum.

Return a JSON object with this EXACT structure:
{
  "plantName": "$plantName",
  "diseaseName": "$diseaseName",
  "whyItCame": "Brief 1-2 sentence explanation of why this disease occurred in $language",
  "howItCame": "Brief 1-2 sentence explanation of how this disease spreads in $language",
  "preventionNow": "Brief 1-2 sentence treatment advice for now in $language",
  "preventionFuture": "Brief 1-2 sentence prevention advice for future in $language",
  "recommendedFertilizers": [
    "Fertilizer name 1 in $language",
    "Fertilizer name 2 in $language",
    "Fertilizer name 3 in $language"
  ]
}
Keep all answers SHORT and CONCISE in $language language only.
''';

      final response = await _model.generateContent(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(
          temperature: 0.4,
          topK: 32,
          topP: 1,
          maxOutputTokens: 4096,
        ),
      );

      final text = response.text;
      if (text == null || text.isEmpty) {
        throw Exception('No response from Gemini AI');
      }

      // Extract JSON from response (handle markdown code blocks)
      String jsonString = text.trim();
      if (jsonString.startsWith('```json')) {
        jsonString = jsonString.substring(7);
      } else if (jsonString.startsWith('```')) {
        jsonString = jsonString.substring(3);
      }
      if (jsonString.endsWith('```')) {
        jsonString = jsonString.substring(0, jsonString.length - 3);
      }
      jsonString = jsonString.trim();

      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return DiseaseRemedy.fromJson(jsonData);
    } catch (e) {
      print('Error getting remedy: $e');
      // Return fallback remedy
      return DiseaseRemedy(
        plantName: plantName,
        diseaseName: diseaseName,
        whyItCame: 'Unable to retrieve disease information. Please consult an expert.',
        howItCame: 'Unable to retrieve disease information. Please consult an expert.',
        preventionNow: 'Consult with a local agricultural expert immediately.',
        preventionFuture: 'Maintain proper soil nutrition and regular monitoring.',
        recommendedFertilizers: [
          'Balanced NPK fertilizer',
          'Organic compost',
        ],
      );
    }
  }
}
