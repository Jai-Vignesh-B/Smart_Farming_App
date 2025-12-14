import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart'; 
import 'package:farmer_app/screens/user_profile_screen.dart';
import 'package:farmer_app/screens/carbon_credit_screen.dart';
import 'package:farmer_app/screens/crop_advisory_screen.dart';
import 'package:farmer_app/screens/disease_detection_screen.dart';
import 'package:farmer_app/screens/govt_schemes_screen.dart';
import 'package:farmer_app/screens/crop_recommendation_screen.dart';
import 'package:farmer_app/screens/insurance_screen.dart';
import 'package:farmer_app/screens/market_prices_screen.dart';
import 'package:farmer_app/screens/settings_screen.dart';
import 'package:farmer_app/screens/voice_assistant_screen.dart';
import 'package:farmer_app/theme/app_theme.dart';
import 'package:farmer_app/widgets/glass_container.dart';
import 'package:farmer_app/widgets/weather_card.dart';
import 'package:farmer_app/widgets/chat_bot_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:farmer_app/providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightBackground,
      body: Stack(
        children: [
          // Scrollable Content
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120), // Space for BottomNav + FAB
              child: Stack(
                children: [
                  // Green Background (Scrolls with content)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 320,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                    ),
                  ),

                  // Content
                  SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 10),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0), // Match other padding
                          child: WeatherCard(),
                        ),
                        
                        const SizedBox(height: 32),
      
                        // Market Prices Section
                        _buildSectionHeader("marketPrices".tr(), () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketPricesScreen()));
                        }),
                        const SizedBox(height: 16),
                        _buildMarketPriceCard(),
      
                        const SizedBox(height: 32),
      
                        // Services / My Fields Section
                        _buildSectionHeader("myServices".tr(), () {}),
                        const SizedBox(height: 16),
                        _buildServicesGrid(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Chat Bot Floating Button (Widget manages its own position)
          const ChatBotWidget(),

          // Bottom Navigation Bar (Fixed)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.userChanges(),
                    initialData: FirebaseAuth.instance.currentUser,
                    builder: (context, snapshot) {
                      return Text(
                        "hello".tr(args: [snapshot.data?.displayName?.split(' ')[0] ?? 'Farmer']),
                        style: TextStyle(color: AppColors.primaryLight, fontSize: 14),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d MMM', context.locale.languageCode).format(DateTime.now()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: const Icon(LucideIcons.user, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketPriceCard() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        elevation: 2,
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MarketPricesScreen()));
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              // color: Colors.white, // Moved to Material
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.trendingUp, color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "liveMandiPrices".tr(),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                      ),
                      Text(
                        "checkPrices".tr(),
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey),
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, color: isDark ? Colors.white54 : Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServicesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Featured Item (Disease Detection)
          _buildFeaturedService(
            "diseaseDetection".tr(),
            "treatmentAdvice".tr(), 
            "https://images.unsplash.com/photo-1500382017468-9049fed747ef?q=80&w=800",
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiseaseDetectionScreen())),
          ),
          const SizedBox(height: 16),
          // Grid
          Row(
            children: [
              Expanded(
                child: _buildServiceCard(
                  "govtSchemes".tr(),
                  LucideIcons.landmark,
                  Colors.blue,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GovtSchemesScreen())),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildServiceCard(
                  "cropAdvisory".tr(),
                  LucideIcons.sprout,
                  AppColors.primary,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CropAdvisoryScreen())),
                ),
              ),
            ],
          ),
           const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildServiceCard(
                  "carbonCredit".tr(), 
                  LucideIcons.aperture,
                  Colors.teal,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CarbonCreditScreen())),
                  imagePath: 'assets/images/drone.png',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildServiceCard(
                  "cropToGrow".tr(), 
                  LucideIcons.leaf, // Leaf icon for "Grow"
                  Colors.green,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CropRecommendationScreen())),
                ),
              ), 
            ],
          ),
          const SizedBox(height: 16),
          // Other services can be listed here...
        ],
      ),
    );
  }
  
  Widget _buildFeaturedService(String title, String subtitle, String imageUrl, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.7)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.camera, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(String title, IconData icon, Color color, VoidCallback onTap, {String? imagePath}) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100, // Fixed height for uniformity
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(isDark ? 0.4 : 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: isDark ? color.withOpacity(0.3) : Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 4)]),
              child: imagePath != null 
                  ? Image.asset(imagePath, width: 20, height: 20, color: color)
                  : Icon(icon, color: color, size: 20),
            ),
            Flexible(
              child: Text(
                title, 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.grey[800]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildBottomNav() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: isDark ? Colors.black26 : Colors.black12, blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(LucideIcons.sprout, "navHome".tr(), 0),
          _navItem(LucideIcons.mic, "voiceAssistant".tr(), 1),
          _navItem(LucideIcons.settings, "settings".tr(), 2),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        // Simple Navigation Logic for demo
        if (index == 2) {
           Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())).then((_) {
             // Refresh UI when returning from settings (for language changes)
             if (mounted) setState(() => _currentIndex = 0);  // Reset to Home
           });
        } else if (index == 1) {
           Navigator.push(context, MaterialPageRoute(builder: (_) => VoiceAssistantScreen(key: ValueKey(context.locale)))).then((_) {
             if (mounted) setState(() => _currentIndex = 0);  // Reset to Home
           });
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? AppColors.primary : Colors.grey[400], size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.primary : Colors.grey[400],
            ),
          ),
          if (isSelected) 
            Container(margin: const EdgeInsets.only(top: 4), width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle))
        ],
      ),
    );
  }
}

