import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:farmer_app/models/soil_data.dart';
import 'package:farmer_app/providers/theme_provider.dart';
import 'package:farmer_app/services/api_service.dart';
import 'package:farmer_app/services/soil_service.dart';
import 'package:farmer_app/theme/app_theme.dart';

import 'package:farmer_app/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CropAdvisoryScreen extends StatefulWidget {
  const CropAdvisoryScreen({super.key});

  @override
  State<CropAdvisoryScreen> createState() => _CropAdvisoryScreenState();
}

class _CropAdvisoryScreenState extends State<CropAdvisoryScreen> {
  final SoilService _soilService = SoilService();
  final ApiService _apiService = ApiService();

  SoilData? _soilData;
  Map<String, dynamic>? _geminiAnalysis;
  bool _isLoading = true;
  bool _isAnalyzing = false;
  String? _error;

  StreamSubscription<SoilData?>? _subscription;
  String? _lastLocale;

  @override
  void initState() {
    super.initState();
    _lastLocale = 'en';
    _subscribeToStream();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = context.locale.languageCode;
    
    // Re-analyze if language changed and we have soil data
    if (_lastLocale != null && _lastLocale != currentLocale && _soilData != null) {
      setState(() {
        _lastLocale = currentLocale;
        _geminiAnalysis = null; // Clear old analysis
      });
      _analyzeSoil(_soilData!);
    } else {
      _lastLocale = currentLocale;
    }
  }

  void _subscribeToStream() {
    _subscription = _soilService.getSoilStream().listen((data) {
      if (mounted) {
        setState(() {
          _soilData = data;
          _isLoading = false;
          _error = null;
        });

        // Auto-analyze only if we haven't analyzed yet and data is valid
        if (data != null && _geminiAnalysis == null && !_isAnalyzing) {
          _analyzeSoil(data);
        }
      }
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _error = "Connection Error: $e";
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _manualRefresh() async {
    // Re-trigger analysis with current data
    if (_soilData != null) {
      _analyzeSoil(_soilData!);
    }
  }

  Future<void> _analyzeSoil(SoilData data) async {
    setState(() => _isAnalyzing = true);
    try {
      final analysis = await _apiService.analyzeSoilHealth(data, context.locale.languageCode);
      if (mounted) {
        setState(() {
          _geminiAnalysis = analysis;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Container(
      decoration: isDark ? const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F4C3A), // Dark Green
            Color(0xFF1E293B), // Slate Dark
            Color(0xFF134E5E), // Teal
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ) : BoxDecoration(
        color: AppColors.lightBackground, // Flat light background
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'cropAdvisory'.tr(),
            style: GoogleFonts.outfit(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold),
          ),
          iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF1E293B)),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.refreshCw),
              onPressed: _manualRefresh,
              tooltip: "refreshData".tr(),
            )
          ],
        ),
        body: _buildBody(isDark),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: isDark ? Colors.white : AppColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            TextButton(
              onPressed: _manualRefresh,
              child: const Text("Retry", style: TextStyle(color: Colors.greenAccent)),
            )
          ],
        ),
      );
    }

    if (_soilData == null) {
      return Center(
        child: Text(
          "noSoilDataFound".tr(),
          style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 16),
        ),
      );
    }

    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NPK Card
          _buildNPKCard(_soilData!, isDark),
          
          const SizedBox(height: 24),
          
          Text(
            "aiSoilAnalysis".tr(),
            style: GoogleFonts.outfit(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_isAnalyzing)
             Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_geminiAnalysis != null && _geminiAnalysis!.isNotEmpty)
            _buildAnalysisContent(_geminiAnalysis!, isDark)
          else if (_geminiAnalysis != null && _geminiAnalysis!.containsKey('error'))
            Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
               ),
               child: Row(
                 children: [
                   const Icon(LucideIcons.alertCircle, color: Colors.redAccent, size: 20),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Text(
                       _geminiAnalysis!['error'] ?? "analysisFailed".tr(),
                       style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.black54),
                     ),
                   ),
                 ],
               ),
            )
          else
            Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300),
               ),
               child: Text("analysisUnavailable".tr(), style: TextStyle(color: isDark ? Colors.white70 : Colors.grey)),
            ),
        ],
      ),
    );
  }

  Widget _buildNPKCard(SoilData data, bool isDark) {
    final bgColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white;
    final borderColor = isDark ? Colors.transparent : Colors.grey.shade200;
    final shadow = isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 5))];

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: shadow
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "mySoilDataNPK".tr(),
                style: GoogleFonts.outfit(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 16),
              ),
               Icon(LucideIcons.database, color: Colors.greenAccent.shade200, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildElementBadge("nitrogen".tr(), "N", data.nitrogen.toStringAsFixed(1), Colors.blueAccent, isDark),
              _buildElementBadge("phosphorus".tr(), "P", data.phosphorus.toStringAsFixed(1), Colors.orangeAccent, isDark),
              _buildElementBadge("potassium".tr(), "K", data.potassium.toStringAsFixed(1), Colors.purpleAccent, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildElementBadge(String name, String symbol, String value, Color color, bool isDark) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            color: color.withValues(alpha: 0.2),
          ),
          child: Center(
            child: Text(
              symbol,
              style: GoogleFonts.outfit(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 16),
        ),
         Text(
          name,
          style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAnalysisContent(Map<String, dynamic> analysis, bool isDark) {
    return Column(
      children: [
        // Soil Health & Type
        _buildInfoCard(
          title: "soilHealth".tr(),
          content: analysis['soil_health'] ?? "Unknown",
          icon: LucideIcons.heartPulse,
          color: Colors.redAccent,
          subtitle: analysis['soil_type'],
          isDark: isDark
        ),
        const SizedBox(height: 16),
        
        // Crops
        if (analysis['crops'] != null)
          _buildListCard(
            title: "recommendedCrops".tr(),
            items: List<String>.from(analysis['crops']),
            icon: LucideIcons.wheat,
            color: const Color(0xFF059669), // Emerald green for readability
            isDark: isDark
          ),
          
        const SizedBox(height: 16),
         
        // Fertilizers
        if (analysis['fertilizers'] != null)
           _buildListCard(
            title: "fertilizers".tr(),
            items: List<String>.from(analysis['fertilizers']),
            icon: LucideIcons.sprout,
            color: const Color(0xFF0891B2), // Cyan for better contrast
            isDark: isDark
          ),
          
        const SizedBox(height: 16),
        
        // Diseases
        if (analysis['diseases'] != null)
          ...((analysis['diseases'] as List).map((d) => _buildDiseaseCard(d, isDark)).toList()),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    String? subtitle,
    required bool isDark,
  }) {
    final bgColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final shadow = isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 5))];
    final borderColor = isDark ? Colors.transparent : Colors.grey.shade200;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: shadow
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.grey[600], fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  content,
                  style: GoogleFonts.outfit(color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.grey[800], height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    final bgColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final shadow = isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 5))];
    final borderColor = isDark ? Colors.transparent : Colors.grey.shade200;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: shadow
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item, 
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseCard(Map<String, dynamic> disease, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3), width: 1.5),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon on the left
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.alertTriangle, 
                color: Colors.redAccent, 
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Content on the right
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    disease['name'] ?? "unknownRisk".tr(),
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${"treatment".tr()}: ${disease['solution'] ?? 'noSolutionListed'.tr()}",
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.grey[800],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
