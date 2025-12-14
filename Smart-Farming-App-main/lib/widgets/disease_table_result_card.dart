import 'package:easy_localization/easy_localization.dart';
import 'package:farmer_app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmer_app/services/gemini_disease_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

class DiseaseTableResultCard extends StatefulWidget {
  final DiseaseRemedy remedy;
  final double? confidence;

  const DiseaseTableResultCard({
    super.key,
    required this.remedy,
    this.confidence,
  });

  @override
  State<DiseaseTableResultCard> createState() => _DiseaseTableResultCardState();
}

class _DiseaseTableResultCardState extends State<DiseaseTableResultCard> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speakAllInfo() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
    } else {
      final textToRead = '''
${'diseaseName'.tr()}: ${widget.remedy.diseaseName}.
${'whyItCame'.tr()}: ${widget.remedy.whyItCame}.
${'howItCame'.tr()}: ${widget.remedy.howItCame}.
${'preventionNow'.tr()}: ${widget.remedy.preventionNow}.
${'preventionFuture'.tr()}: ${widget.remedy.preventionFuture}.
${'recommendedFertilizers'.tr()}: ${widget.remedy.recommendedFertilizers.join(', ')}.
''';
      
      await _flutterTts.setLanguage(context.locale.languageCode);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.speak(textToRead);
      setState(() => _isSpeaking = true);
      
      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() => _isSpeaking = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final isHealthy = widget.remedy.diseaseName.toLowerCase().contains("healthy") || 
                      widget.remedy.diseaseName.toLowerCase().contains("स्वस्थ") || 
                      widget.remedy.diseaseName.toLowerCase().contains("ਸਿਹਤਮੰਦ");

    // Adaptive Colors
    final bgColor = isHealthy 
        ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5)) // Emerald 900 vs 50
        : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2)); // Red 900 vs 50
    
    final borderColor = isHealthy
        ? (isDark ? const Color(0xFF059669) : const Color(0xFF10B981))
        : (isDark ? const Color(0xFFEF4444) : const Color(0xFFEF4444).withOpacity(0.3));

    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final subTextColor = isDark ? Colors.white70 : Colors.grey[600];
    final tableBg = isDark ? Colors.white.withOpacity(0.05) : Colors.white; // Glassy dark or White

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Disease Name and Speaker
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isHealthy ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isHealthy ? Icons.check : Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.remedy.diseaseName,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.confidence != null)
                      Text(
                        "${'confidence'.tr()}: ${(widget.confidence! * 100).toStringAsFixed(1)}%",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: subTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    Text(
                      widget.remedy.plantName,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: subTextColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              // Speaker button
              GestureDetector(
                onTap: _speakAllInfo,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isSpeaking 
                        ? const Color(0xFF059669) 
                        : (isDark ? Colors.white10 : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isSpeaking 
                          ? const Color(0xFF059669)
                          : (isDark ? Colors.white24 : Colors.grey[300]!),
                    ),
                  ),
                  child: Icon(
                    _isSpeaking ? Icons.volume_up : Icons.volume_off,
                    size: 24,
                    color: _isSpeaking ? Colors.white : (isDark ? Colors.white70 : Colors.grey[600]),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Table Format
          Container(
            decoration: BoxDecoration(
              color: tableBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                _buildTableRow('diseaseName'.tr(), widget.remedy.diseaseName, true, isDark),
                _buildDivider(isDark),
                _buildTableRow('whyItCame'.tr(), widget.remedy.whyItCame, false, isDark),
                _buildDivider(isDark),
                _buildTableRow('howItCame'.tr(), widget.remedy.howItCame, false, isDark),
                _buildDivider(isDark),
                _buildTableRow('preventionNow'.tr(), widget.remedy.preventionNow, false, isDark),
                _buildDivider(isDark),
                _buildTableRow('preventionFuture'.tr(), widget.remedy.preventionFuture, false, isDark),
                _buildDivider(isDark),
                _buildTableRowWithList(
                  'recommendedFertilizers'.tr(),
                  widget.remedy.recommendedFertilizers,
                  isDark
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(String question, String answer, bool isFirst, bool isDark) {
    return Padding(
      padding: EdgeInsets.all(isFirst ? 16 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              question,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF059669), // Keep green/primary
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              answer,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.white70 : const Color(0xFF374151),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRowWithList(String question, List<String> items, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              question,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF059669),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key + 1}. ',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF059669),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : const Color(0xFF374151),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? Colors.white10 : Colors.grey[200],
    );
  }
}
