import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:farmer_app/providers/theme_provider.dart';
import 'package:farmer_app/screens/auth_screen.dart';
import 'package:farmer_app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await EasyLocalization.ensureInitialized();
  
  // Hide System Navigation Bar (Immersive Mode)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  // Initialize Firebase
  // We explicitly provide options for Android to ensure the correct Database URL is used (Region: asia-southeast1)
  // This overrides the default behavior which might default to US if google-services.json is missing the url.
  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
       await Firebase.initializeApp(
         options: const FirebaseOptions(
           apiKey: 'AIzaSyAzHmuY2oceZDZh8VKFz2m4oyUiWejyATo',
           appId: '1:611544855938:android:e43800f7b63611bab00b9b',
           messagingSenderId: '611544855938',
           projectId: 'sihp-2025',
           storageBucket: 'sihp-2025.firebasestorage.app',
           databaseURL: 'https://sihp-2025-default-rtdb.asia-southeast1.firebasedatabase.app',
         ),
       );
    } else {
       await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint("Firebase Initialization Failed: $e");
    // If it fails (e.g. already initialized), we ignore or handle. 
    // Usually it throws failing to initialize if called twice, but we are at start.
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('pa'),
        Locale('ta'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const FarmerApp(),
      ),
    ),
  );
}

class FarmerApp extends StatelessWidget {
  const FarmerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Farmer App',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const AuthScreen(),
        );
      },
    );
  }
}
