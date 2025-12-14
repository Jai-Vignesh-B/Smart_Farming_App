import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  late final GenerativeModel _model;
  late final ChatSession _chat;
  
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? "";

  static const String _systemInstruction = """
You are "Crop Nexa AI", a digital farm assistant powered by Gemini. You are the core intelligence of the "Crop Nexa 2.3" application.
Your goal is to assist small and marginal farmers with smart crop advisory, market prices, and farming techniques.

---
**YOUR CAPABILITIES & BEHAVIOR:**

**1. General Agricultural Expert:**
- You are an expert agronomist. You **MUST** answer general questions about farming, crop diseases, pest control, soil health, and fertilizer management.
- **Topics You Cover:**
  - **Weather:** Forecasts and farming impact.
  - **Market Prices:** Live mandi prices, trends for all products (Vegetables, Fruits, Grains).
  - **Diseases:** Detection, prevention, and cure for crops.
  - **Government Schemes:** Explain PM-Kisan, subsidies, insurance (PMFBY), and other schemes.
  - **Crop Advisory:** Sowing to harvesting guide.
  - **Soil & Nutrients:** NPK (Nitrogen, Phosphorus, Potassium), minerals, soil testing, soil health card.
  - **Tech:** Agricultural drones (spraying, monitoring), modern equipment.
  - **Inputs:** Fertilizers (Nano Urea, DAP), Seeds, Pesticides.

- **Market Prices Note:** If a user asks for prices, provide estimated ranges based on general knowledge for the Indian market or use provided context.
- **Crop Advisory:** Provide detailed steps for growing crops, treating diseases, and optimizing yield.

**2. Crop Nexa 2.3 Project Context (Use this for specific app features):**
- **Drone Booking:** We offer a Kisan group rental model at ₹200–₹300/acre for spraying.
- **Nano-Fertilizers:** Guidance to reduce cost by ~33% and increase yield.
- **Flood Resilience:** We provide early alerts (partners: Skymet, AccuWeather).
- **Carbon Credits:** Farmers can earn extra income through sustainable farming (partners: Boomitra, GrowIndigo).
- **Direct Market:** A platform to sell directly to buyers, bypassing middlemen.


**3. Interaction Style:**
- Be helpful, encouraging, and empathetic to farmers.
- Use simple, clear language.
- Promote sustainable practices.
- **Voice/Language:** You support multilingual interactions.

---
**Example Scenarios:**
- If asked "What is PM Kisan?", explain the scheme simply.
- If asked "What is NPK ratio for Wheat?", explain Nitrogen, Phosphorus, Potassium needs.
- If asked "How do drones help?", explain spraying efficiency and labor saving.

**CRITICAL: DOMAIN RESTRICTION**
- You must **ONLY** answer questions related to **Agriculture, Farming, Crops, Market Prices (Mandi), Pest Control, Weather, Gov Schemes, Soil, or Rural Development**.
- If a user asks about anything else (e.g., **Cricket**, **Movies**, **Politics**, **General News**, **Jokes**, **Personal Advice**, **Coding**, **Math**), you **MUST politely refuse**.
- **DO NOT** answer non-agricultural questions even if you know the answer.
- Refusal Example: "I am a farming assistant. I can only help you with agriculture and market prices." (Translate this to the target language).
""";

  ChatService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', // Using gemini-2.5-flash as requested
      apiKey: _apiKey,
      systemInstruction: Content.system(_systemInstruction),
    );
    _chat = _model.startChat(history: []);
  }

  Future<String> sendMessage(String message, String languageCode) async {
    try {
      String languagePrompt = '';
      
      switch (languageCode) {
        case 'hi':
          languagePrompt = 'IMPORTANT: Respond in HINDI (Devanagari script) ONLY. Do not use English. Example: "नमस्ते, मैं आपकी कैसे मदद कर सकता हूँ?"';
          break;
        case 'pa':
          languagePrompt = 'IMPORTANT: Respond in PUNJABI (Gurmukhi script) ONLY. Do not use English. Example: "ਸਤਿ ਸ਼੍ਰੀ ਅਕਾਲ, ਮੈਂ ਤੁਹਾਡੀ ਕਿਵੇਂ ਮਦਦ ਕਰ ਸਕਦਾ ਹਾਂ?"';
          break;
        case 'ta':
          languagePrompt = 'IMPORTANT: Respond in TAMIL script ONLY. Do not use English. Example: "வணக்கம், நான் உங்களுக்கு எப்படி உதவ முடியும்?"';
          break;
        case 'en': 
        default:
          languagePrompt = 'Respond in English.';
      }

      final prompt = "$languagePrompt\n\nUser Question: $message";
      final content = Content.text(prompt);
      final response = await _chat.sendMessage(content);
      return response.text ?? "I could not understand. Please try again.";
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<String> getCropRecommendations(String state, String weatherSummary, String languageCode) async {
    try {
      String languagePrompt = '';
      switch (languageCode) {
        case 'hi': languagePrompt = 'OUTPUT IN HINDI ONLY.'; break;
        case 'pa': languagePrompt = 'OUTPUT IN PUNJABI ONLY.'; break;
        case 'ta': languagePrompt = 'OUTPUT IN TAMIL ONLY.'; break;
        default: languagePrompt = 'OUTPUT IN ENGLISH ONLY.'; break;
      }

      final prompt = """
      $languagePrompt
      CONTEXT:
      - Location: $state, India
      - Current Weather: $weatherSummary
      
      TASK:
      Recommend exactly 6 crops. Use the following CRITERIA STRICTLY:
      1. The crop MUST be suitable for the Current Weather provided in the CONTEXT.
      2. The crop MUST have a high market value and profitability right now.
      
      Combine these two factors. Do not recommend crops that grow in this weather but have low profit, or high profit crops that cannot survive this weather.
      
      OUTPUT FORMAT:
      Return ONLY a pure valid JSON object (no markdown, no backticks) with this structure:
      {
        "crops": [
          {
            "name": "Crop Name",
            "reason": "Brief reason why it's good for this weather",
            "marketPrice": "₹X - ₹Y / quintal"
          }
        ]
      }
      
      Make sure the "marketPrice" is a realistic estimate for the Indian market.
      The entire content (names, reasons) MUST be in the requested language.
      """;

      final content = Content.text(prompt);
      final response = await _model.generateContent([content]);
      return response.text?.replaceAll('```json', '').replaceAll('```', '').trim() ?? "{}";
    } catch (e) {
      return "Error: $e";
    }
  }
}
