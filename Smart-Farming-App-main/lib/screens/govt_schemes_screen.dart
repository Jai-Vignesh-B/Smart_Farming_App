import 'package:easy_localization/easy_localization.dart';
import 'package:farmer_app/providers/theme_provider.dart';
import 'package:farmer_app/theme/app_theme.dart';
import 'package:farmer_app/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class GovtSchemesScreen extends StatelessWidget {
  const GovtSchemesScreen({super.key});

  final List<Map<String, dynamic>> _schemes = const [
    {
      'id': 'crm',
      'icon': LucideIcons.wrench,
      'color': Colors.orange,
      'url': 'https://agrimachinerypb.com/',
    },
    {
      'id': 'dsr',
      'icon': LucideIcons.sprout,
      'color': Colors.green,
      'url': 'https://agri.punjab.gov.in/',
    },
    {
      'id': 'epmb',
      'icon': LucideIcons.store,
      'color': Colors.amber,
      'url': 'https://emandikaran-pb.in/',
    },
    {
      'id': 'midh',
      'icon': LucideIcons.apple,
      'color': Colors.redAccent,
      'url': 'https://horticulture.punjab.gov.in/',
    },
    {
      'id': 'paani',
      'icon': LucideIcons.droplets,
      'color': Colors.blue,
      'url': 'https://www.pspcl.in/',
    },
    {
      'id': 'smam',
      'icon': LucideIcons.plane,
      'color': Colors.purple,
      'url': 'https://agrimachinery.nic.in/',
    },
    {
      'id': 'pmkisan',
      'icon': LucideIcons.indianRupee,
      'color': Colors.teal,
      'url': 'https://pmkisan.gov.in/',
    },
    {
      'id': 'kusum',
      'icon': LucideIcons.sun,
      'color': Colors.orangeAccent,
      'url': 'https://pmkusum.mnre.gov.in/',
    },
    {
      'id': 'enam',
      'icon': LucideIcons.globe,
      'color': Colors.indigo,
      'url': 'https://enam.gov.in/web/',
    },
    {
      'id': 'soilhealth',
      'icon': LucideIcons.fileBarChart,
      'color': Colors.brown,
      'url': 'https://soilhealth.dac.gov.in/',
    },
  ];

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch \$url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDark ? const Color(0xFF1E293B) : AppColors.lightBackground;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'govtSchemes'.tr(),
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.separated(
          itemCount: _schemes.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final scheme = _schemes[index];
            final id = scheme['id'] as String;
            
            return _buildSchemeCard(
              title: "schemes.$id.title".tr(),
              description: "schemes.$id.description".tr(),
              label: "schemes.$id.label".tr(),
              icon: scheme['icon'] as IconData,
              color: scheme['color'] as Color,
              url: scheme['url'] as String,
              isDark: isDark,
            );
          },
        ),
      ),
    );
  }

  Widget _buildSchemeCard({
    required String title,
    required String description,
    required String label,
    required IconData icon,
    required Color color,
    required String url,
    required bool isDark,
  }) {
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final descColor = isDark ? Colors.white.withOpacity(0.8) : Colors.grey[700];
    final tagBg = isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100];
    final tagText = isDark ? Colors.white70 : Colors.grey[600];
    final borderColor = isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade200;

    return Container(
      decoration: BoxDecoration(
         color: cardColor,
         borderRadius: BorderRadius.circular(20),
         border: Border.all(color: borderColor),
         boxShadow: isDark ? [] : [
           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
         ]
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
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
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: tagText,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              color: descColor,
              height: 1.5,
              fontSize: 14,
            ),
          ),
           const SizedBox(height: 12),
           SizedBox(
             width: double.infinity,
             child: OutlinedButton(
               onPressed: () => _launchUrl(url),
               style: OutlinedButton.styleFrom(
                 side: BorderSide(color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey[300]!),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               ),
               child: Text("viewDetails".tr(), style: TextStyle(color: isDark ? Colors.white : AppColors.primary)),
             ),
           )
        ],
      ),
    );
  }
}
