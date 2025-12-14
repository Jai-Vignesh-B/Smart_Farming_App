import 'package:easy_localization/easy_localization.dart';
import 'package:farmer_app/providers/theme_provider.dart';
import 'package:farmer_app/screens/auth_screen.dart';
import 'package:farmer_app/theme/app_theme.dart';
import 'package:farmer_app/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    
    // Get user data from Firebase Auth (no Firestore needed)
    final name = user?.displayName ?? "Farmer";
    final email = user?.email ?? "No Email";
    final joinDate = user?.metadata.creationTime ?? DateTime.now();
    final formattedDate = DateFormat.yMMMMd().format(joinDate);

    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white60 : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : AppColors.lightBackground,
        gradient: isDark ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F4C3A), // Dark Green
            Color(0xFF1E293B), // Slate Dark
          ],
        ) : null,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(LucideIcons.chevronLeft, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "myProfile".tr(),
            style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.logOut, color: Colors.redAccent),
              onPressed: () => _showLogoutDialog(context, isDark),
            ),
          ],
        ),
        body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Avatar Section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            backgroundImage: const AssetImage('assets/images/logo.png'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Icon(LucideIcons.mail, color: subTextColor, size: 16),
                       const SizedBox(width: 4),
                       Text(
                        email,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 48),

                  // Details Cards
                  _buildInfoTile(
                    icon: LucideIcons.mail,
                    label: "contactInfo".tr(),
                    value: email,
                    isDark: isDark,
                    textColor: textColor,
                    subTextColor: subTextColor,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoTile(
                    icon: LucideIcons.languages,
                    label: "language".tr(),
                    value: _getLanguageName(context.locale.languageCode),
                    isDark: isDark,
                    textColor: textColor,
                    subTextColor: subTextColor,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoTile(
                    icon: LucideIcons.calendar,
                    label: "memberSince".tr(),
                    value: formattedDate,
                    isDark: isDark,
                    textColor: textColor,
                    subTextColor: subTextColor,
                  ),
                ],
              ),
            ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    required Color textColor,
    required Color subTextColor,
  }) {
    // Adaptive container color
    final bgColor = isDark 
        ? Colors.white.withOpacity(0.05) 
        : Colors.black.withOpacity(0.05);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: subTextColor, size: 20),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: subTextColor.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'hi': return 'Hindi (हिंदी)';
      case 'pa': return 'Punjabi (ਪੰਜਾਬੀ)';
      case 'ta': return 'Tamil (தமிழ்)';
      default: return 'English';
    }
  }

  void _showLogoutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("logout".tr(), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: Text("areYouSureLogout".tr(), style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("cancel".tr(), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
               Navigator.pop(context);
               _handleLogout(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text("logout".tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
