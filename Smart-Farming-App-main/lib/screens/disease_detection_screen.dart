import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:farmer_app/providers/theme_provider.dart';
import 'package:farmer_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmer_app/services/gemini_disease_service.dart';
import 'package:farmer_app/screens/manual_disease_search_screen.dart';
import 'package:farmer_app/widgets/disease_table_result_card.dart';
import 'package:provider/provider.dart';

class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  State<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  
  // Gemini Service
  final GeminiDiseaseService _geminiService = GeminiDiseaseService();
  
  // ML State
  bool _loading = false;
  DiseaseDetectionResult? _detectionResult;
  DiseaseRemedy? _remedy;
  
  // Track language to detect changes
  String? _currentLanguage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLanguage = context.locale.languageCode;
    
    // If language changed and we have detection result, re-fetch remedy in new language
    if (_currentLanguage != null && _currentLanguage != newLanguage && _detectionResult != null) {
      _currentLanguage = newLanguage;
      // Re-get remedy in new language
      _getRemedyInNewLanguage();
    } else {
      _currentLanguage = newLanguage;
    }
  }

  Future<void> _getRemedyInNewLanguage() async {
    if (_detectionResult == null) return;
    
    setState(() {
      _loading = true;
    });

    try {
      final languageCode = context.locale.languageCode;
      final remedy = await _geminiService.getRemedyForDisease(
        _detectionResult!.plantName,
        _detectionResult!.diseaseName,
        languageCode,
      );

      if (mounted) {
        setState(() {
          _remedy = remedy;
          _loading = false;
        });
      }
    } catch (e) {
      print("Error re-fetching remedy in new language: $e");
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _loading = true;
        _image = File(pickedFile.path);
        _detectionResult = null;
        _remedy = null;
      });
      _analyzeImage(_image!);
    }
  }

  Future<void> _analyzeImage(File image) async {
    try {
      final languageCode = context.locale.languageCode;
      
      // Step 1: Detect disease using Gemini Vision
      final detection = await _geminiService.detectDiseaseFromImage(
        image,
        languageCode,
      );
      
      if (mounted) {
        setState(() {
          _detectionResult = detection;
        });
      }

      // Step 2: Get remedy and preventive measures
      final remedy = await _geminiService.getRemedyForDisease(
        detection.plantName,
        detection.diseaseName,
        languageCode,
      );

      if (mounted) {
        setState(() {
          _remedy = remedy;
          _loading = false;
        });
      }
    } catch (e) {
      print("Error analyzing image: $e");
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('analysisFailed'.tr()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDark ? const Color(0xFF1E293B) : AppColors.lightBackground;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSubtitle = isDark ? Colors.white70 : Colors.grey[600];
    final containerColor = isDark ? Colors.white.withOpacity(0.1) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('diseaseDetection'.tr(), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
                boxShadow: isDark ? null : [
                   BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 5))
                ]
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            size: 64, color: isDark ? Colors.white54 : Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'uploadImage'.tr(),
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.w600, color: textSubtitle),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'uploadInstruction'.tr(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: isDark ? Colors.white54 : Colors.grey[500], fontSize: 12),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                    child: _buildGlassButton(
                      icon: Icons.camera_alt,
                      label: 'camera'.tr(),
                      onTap: () => _pickImage(ImageSource.camera),
                      isPrimary: true,
                      isDark: isDark
                    ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGlassButton(
                      icon: Icons.photo_library,
                      label: 'gallery'.tr(),
                      onTap: () => _pickImage(ImageSource.gallery),
                      isPrimary: false,
                      isDark: isDark
                    ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Find without image button
            _buildGlassButton(
              icon: Icons.search,
              label: 'findWithoutImage'.tr(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManualDiseaseSearchScreen(),
                  ),
                );
              },
              isPrimary: false,
              isDark: isDark
            ),
            const SizedBox(height: 32),
            
            if (_loading)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else if (_remedy != null && _detectionResult != null)
              DiseaseTableResultCard(
                remedy: _remedy!,
                confidence: _detectionResult!.confidence,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton({required IconData icon, required String label, required VoidCallback onTap, required bool isPrimary, required bool isDark}) {
    // Primary: Green (Adaptive shade?), Secondary: Glass/White
    final primaryColor = const Color(0xFF059669);
    final secondaryBg = isDark ? Colors.white.withOpacity(0.1) : Colors.white;
    final secondaryText = isDark ? Colors.white : const Color(0xFF1E293B);
    final secondaryBorder = isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade300;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? primaryColor : secondaryBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? Colors.transparent : secondaryBorder
          ),
          boxShadow: (!isPrimary && !isDark) ? [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: Offset(0, 2))
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isPrimary ? Colors.white : secondaryText, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isPrimary ? Colors.white : secondaryText, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
