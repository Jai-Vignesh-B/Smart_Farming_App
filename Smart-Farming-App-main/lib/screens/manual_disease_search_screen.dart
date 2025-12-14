import 'package:easy_localization/easy_localization.dart';
import 'package:farmer_app/providers/theme_provider.dart';
import 'package:farmer_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmer_app/services/gemini_disease_service.dart';
import 'package:farmer_app/widgets/disease_table_result_card.dart';
import 'package:provider/provider.dart';

class ManualDiseaseSearchScreen extends StatefulWidget {
  const ManualDiseaseSearchScreen({super.key});

  @override
  State<ManualDiseaseSearchScreen> createState() => _ManualDiseaseSearchScreenState();
}

class _ManualDiseaseSearchScreenState extends State<ManualDiseaseSearchScreen> {
  final TextEditingController _plantNameController = TextEditingController();
  final TextEditingController _diseaseNameController = TextEditingController();
  final GeminiDiseaseService _geminiService = GeminiDiseaseService();
  
  bool _loading = false;
  DiseaseRemedy? _remedy;
  
  // Track language to detect changes
  String? _currentLanguage;
  
  // Store last search to re-search in new language
  String? _lastPlantName;
  String? _lastDiseaseName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLanguage = context.locale.languageCode;
    
    // If language changed and we have previous search, re-search in new language
    if (_currentLanguage != null && _currentLanguage != newLanguage && 
        _lastPlantName != null && _lastDiseaseName != null) {
      _currentLanguage = newLanguage;
      _searchInNewLanguage();
    } else {
      _currentLanguage = newLanguage;
    }
  }

  Future<void> _searchInNewLanguage() async {
    if (_lastPlantName == null || _lastDiseaseName == null) return;
    
    setState(() {
      _loading = true;
    });

    try {
      final languageCode = context.locale.languageCode;
      final remedy = await _geminiService.getRemedyForDisease(
        _lastPlantName!,
        _lastDiseaseName!,
        languageCode,
      );

      if (mounted) {
        setState(() {
          _remedy = remedy;
          _loading = false;
        });
      }
    } catch (e) {
      print("Error re-searching in new language: $e");
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _plantNameController.dispose();
    _diseaseNameController.dispose();
    super.dispose();
  }

  Future<void> _searchDisease() async {
    if (_plantNameController.text.trim().isEmpty || 
        _diseaseNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('pleaseEnterBothFields'.tr()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Store search query for re-searching when language changes
    _lastPlantName = _plantNameController.text.trim();
    _lastDiseaseName = _diseaseNameController.text.trim();

    setState(() {
      _loading = true;
      _remedy = null;
    });

    try {
      final languageCode = context.locale.languageCode;
      final remedy = await _geminiService.getRemedyForDisease(
        _lastPlantName!,
        _lastDiseaseName!,
        languageCode,
      );

      if (mounted) {
        setState(() {
          _remedy = remedy;
          _loading = false;
        });
      }
    } catch (e) {
      print("Error searching disease: $e");
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
    final cardColor = isDark ? Colors.white.withOpacity(0.1) : Colors.white;
    final inputFill = isDark ? Colors.white.withOpacity(0.1) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'manualSearch'.tr(),
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Text
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: isDark ? null : [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 5))
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.search, color: const Color(0xFF059669), size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'manualSearch'.tr(),
                          style: GoogleFonts.outfit(
                            color: textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'manualSearchDescription'.tr(),
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white70 : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Plant Name Input
            Text(
              'plantName'.tr(),
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _plantNameController,
              style: GoogleFonts.inter(color: textColor),
              decoration: InputDecoration(
                hintText: 'plantNameHint'.tr(),
                hintStyle: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.grey[400]),
                filled: true,
                fillColor: inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
                ),
                prefixIcon: Icon(Icons.eco, color: const Color(0xFF059669)),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Disease Name Input
            Text(
              'diseaseNameLabel'.tr(),
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _diseaseNameController,
              style: GoogleFonts.inter(color: textColor),
              decoration: InputDecoration(
                hintText: 'diseaseNameHint'.tr(),
                hintStyle: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.grey[400]),
                filled: true,
                fillColor: inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
                ),
                prefixIcon: Icon(Icons.bug_report, color: const Color(0xFF059669)),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Generate Cure Button
            GestureDetector(
              onTap: _loading ? null : _searchDisease,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF047857)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_loading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    else
                      Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _loading ? 'searching'.tr() : 'generateCure'.tr(),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Result Card
            if (_remedy != null)
              DiseaseTableResultCard(
                remedy: _remedy!,
              ),
          ],
        ),
      ),
    );
  }
}
