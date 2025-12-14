import 'package:easy_localization/easy_localization.dart';
import 'package:farmer_app/screens/home_screen.dart';
import 'package:farmer_app/theme/app_theme.dart';
import 'package:farmer_app/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool isLogin = true;
  bool showLanding = true; // "Get Started" Landing State
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _phoneController = TextEditingController(); // Functions as Email/Phone identifier
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true; // For password visibility toggle
  bool _obscureConfirmPassword = true; // For confirm password visibility toggle

  // Language Data
  final List<Map<String, dynamic>> _languages = [
    {'code': 'en', 'name': 'English', 'native': 'English', 'initial': 'E'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिंदी', 'initial': 'ह'},
    {'code': 'pa', 'name': 'Punjabi', 'native': 'ਪੰਜਾਬੀ', 'initial': 'ਪ'},
    {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்', 'initial': 'த'},
  ];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    // Enforce Immersive Mode (Hide System Nav Bar)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    // Restore system UI if needed, or keep it immersive
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge); 
    _animController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // --- GOOGLE SIGN IN LOGIC ---
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      // 1. Force account picker by signing out first
      await GoogleSignIn().signOut();
      
      // 2. Trigger Google Sign In flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; 
      }

      // 3. Obtain auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        // Update display name if not set
        if (userCredential.user!.displayName == null || userCredential.user!.displayName!.isEmpty) {
          await userCredential.user!.updateDisplayName(googleUser.displayName);
        }
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✨ Google Login Successful!"), backgroundColor: AppColors.success),
          );
           Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
      }
    } catch (e) {
      debugPrint("Google Sign In Error: $e");
      String errorMessage = "Login Failed: ${e.toString()}";
      
      if (e.toString().contains("network")) {
        errorMessage = "Network Error. Check your connection.";
      } else if (e.toString().contains("10") || e.toString().contains("12500")) {
        errorMessage = "Configuration Error: SHA-1 Key Missing in Firebase.";
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if passwords match for signup
    if (!isLogin && _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.alertTriangle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text("passwordsDoNotMatch".tr()),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      final email = _phoneController.text.contains('@') 
          ? _phoneController.text.trim() 
          : "${_phoneController.text.trim()}@farmerapp.com"; // Fallback for phone-as-email
      final password = _passwordController.text.trim();

      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      } else {
        UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        
        // Update Display Name immediately
        if (cred.user != null) {
          try {
            await cred.user!.updateDisplayName(_nameController.text.trim());
            await cred.user!.reload(); 
          } catch (e) {
            debugPrint("Display Name Update Error: $e");
          }
        }
      }

      if (mounted) {
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } on FirebaseAuthException catch (e) {
      String message = "Authentication Failed";
      
      // Smart Error Handling: Check if they are using a Google Account with a Password
      if (isLogin && (e.code == 'wrong-password' || e.code == 'invalid-credential')) {
         try {
           final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(_phoneController.text.trim()); // Use raw input or constructed email? Use constructed 'email' var from scope if possible, or reconstruct.
           // Reconstruct email here for safety as 'email' var is local to try block
           String checkEmail = _phoneController.text.contains('@') ? _phoneController.text.trim() : "${_phoneController.text.trim()}@farmerapp.com";
           final userMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(checkEmail);
           
           if (userMethods.contains('google.com')) {
             message = "This email uses Google Sign In. Please tap the Google button.";
           } else {
             message = "Incorrect Password.";
           }
         } catch (_) {
           message = "Incorrect Password or Email.";
         }
      } else if (e.code == 'user-not-found') {
        message = "Account not found. Please Sign Up.";
      } else if (e.code == 'email-already-in-use') {
        message = "Account exists! Switching to Login...";
        if (mounted) {
           setState(() {
             isLogin = true;
             _nameController.clear();
             _locationController.clear();
           });
        }
      } else if (e.code == 'weak-password') {
        message = "Password is too weak (min 6 chars).";
      } else {
        message = e.message ?? "An error occurred.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(message.contains("Google") ? LucideIcons.chrome : LucideIcons.alertCircle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ), 
            backgroundColor: message.contains("Google") ? Colors.blueAccent : AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          )
        );
      }
    } catch (e) {
      debugPrint("GENERAL ERROR: $e");
      String msg = "Error: $e";
      if (e.toString().contains("no FirebaseApp")) {
         msg = "Missing google-services.json! Cannot Authenticate.";
      } else if (e.toString().contains("network")) {
         msg = "Network Error. Check your connection.";
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Full Screen Background Image
          Positioned.fill(
            child: Image.network(
              "https://images.unsplash.com/photo-1625246333195-78d9c38ad449?q=80&w=1920&auto=format&fit=crop",
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: AppColors.darkBackground),
            ),
          ),
          
          // 2. Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),

          // 3. Floating 3D Stats (Decorative) - Only shown on Landing
          if (showLanding) ...[
            _buildFloatingStat(
              top: MediaQuery.of(context).size.height * 0.25,
              left: 24,
              icon: LucideIcons.leaf,
              color: AppColors.success,
              label: "Growth",
              value: "12 cm",
              delay: 0,
            ),
            _buildFloatingStat(
              top: MediaQuery.of(context).size.height * 0.35,
              right: 24,
              icon: LucideIcons.droplets,
              color: Colors.blue,
              label: "Moisture",
              value: "75%",
              delay: 200,
            ),
          ],

          // 4. Content Content
          Positioned.fill(
             child: SafeArea(
              child: showLanding ? _buildLandingView() : Form(key: _formKey, child: _buildAuthView()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandingView() {
    return Container(
      width: double.infinity,
      // Ensure height is constrained to max available space or specific height
      constraints: const BoxConstraints.expand(), 
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end, // Push content to bottom
        children: [
            FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Hug content
              children: [
                   Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32), // Agri Green
                      borderRadius: BorderRadius.circular(100), // Circular
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
                    ),
                    child: CircleAvatar(
                       radius: 40,
                       backgroundColor: Colors.transparent,
                       backgroundImage: AssetImage('assets/images/logo.png'),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  "SMART FARMING",
                  style: TextStyle(
                    color: Colors.greenAccent[400],
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "THE NEW ERA\nOF AGRICULTURE",
                  style: TextStyle(
                    fontSize: 42,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 4,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Sustainable farming solutions for a better tomorrow. AI-driven insights at your fingertips.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Get Started Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      print("🚀 'Get Started' Button Clicked!");
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                         print("✅ User already logged in -> Navigating to Home");
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                        );
                      } else {
                         print("👤 No user -> Showing Auth Form");
                        setState(() => showLanding = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B), // Dark Button
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          "Get Started",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(LucideIcons.chevronRight, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAuthView() {
    final currentLocale = context.locale.languageCode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => showLanding = true),
                icon: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 32),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "chooseLanguage".tr(), // Use generic title or specific
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            "chooseLanguage".tr(),
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),

          const SizedBox(height: 24),

          // Use GridView with shrinkWrap for Language Selection
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _languages.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final lang = _languages[index];
              final isSelected = currentLocale == lang['code'];
              return GestureDetector(
                onTap: () async {
                  await context.setLocale(Locale(lang['code']));
                  setState(() {});
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.9) : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryLight : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white24,
                        child: Text(lang['initial'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lang['native'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(lang['name'], style: const TextStyle(color: Colors.white54, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 32),

          // Login/Signup Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(child: _buildAuthTab("userLogin".tr(), isLogin, () {
                  setState(() {
                    isLogin = true;
                    // Clear fields on switch
                     _phoneController.clear();
                     _passwordController.clear();
                     _nameController.clear();
                     _locationController.clear();
                  });
                })),
                Expanded(child: _buildAuthTab("signUp".tr(), !isLogin, () {
                  setState(() {
                    isLogin = false;
                    // Clear fields on switch
                     _phoneController.clear();
                     _passwordController.clear();
                     _nameController.clear(); 
                     _locationController.clear();
                  });
                })),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (!isLogin) ...[
             _buildGlassTextField(controller: _nameController, hint: "fullName".tr(), icon: LucideIcons.user, isRequired: true),
             const SizedBox(height: 16),
             _buildGlassTextField(controller: _locationController, hint: "locationHint".tr(), icon: LucideIcons.mapPin, isRequired: true),
             const SizedBox(height: 16),
          ],
          
          _buildGlassTextField(controller: _phoneController, hint: "phoneEmail".tr(), icon: LucideIcons.phone, isRequired: true),
          const SizedBox(height: 16),
          _buildGlassTextField(controller: _passwordController, hint: "password".tr(), icon: LucideIcons.lock, isPassword: true, isRequired: true),
          
          // Confirm Password (only for signup)
          if (!isLogin) ...[
            const SizedBox(height: 16),
            _buildGlassTextField(
              controller: _confirmPasswordController, 
              hint: "confirmPassword".tr(), 
              icon: LucideIcons.shieldCheck, 
              isPassword: true, 
              isRequired: true,
              isConfirmPassword: true,
            ),
          ],
          
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleAuth,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isLogin ? LucideIcons.logIn : LucideIcons.userPlus, size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(isLogin ? "loginAction".tr() : "signupAction".tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _signInWithGoogle,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
              ),
              icon: const Icon(LucideIcons.chrome, color: Colors.white), 
              label: Text("googleSignIn".tr(), style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),

          const SizedBox(height: 32),

          Center(
            child: Text(
              "termsCondition".tr(),
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          const SizedBox(height: 48), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildAuthTab(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? AppColors.darkSurface : Colors.white60,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    bool isRequired = false,
    bool isPassword = false,
    bool isConfirmPassword = false,
  }) {
    // Determine which obscure state to use
    bool currentObscure = isConfirmPassword ? _obscureConfirmPassword : (isPassword ? _obscurePassword : obscureText);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassContainer(
          color: Colors.white, // Tint
          opacity: 0.1,
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextFormField(
            controller: controller,
            obscureText: currentObscure,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              icon: Icon(icon, color: Colors.white70, size: 20),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              // Use RichText for Hint with Red Asterisk if required
              label: RichText(
                text: TextSpan(
                  text: hint,
                  style: const TextStyle(color: Colors.white38, fontSize: 16),
                  children: [
                    if (isRequired)
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              // Password visibility toggle
              suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              suffixIcon: (isPassword || isConfirmPassword) ? GestureDetector(
                onTap: () {
                  setState(() {
                    if (isConfirmPassword) {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    } else {
                      _obscurePassword = !_obscurePassword;
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    currentObscure ? LucideIcons.eyeOff : LucideIcons.eye,
                    color: Colors.white70,
                    size: 22,
                  ),
                ),
              ) : null,
            ),
            validator: (value) {
              if (isRequired && (value == null || value.trim().isEmpty)) {
                return '$hint is required';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildFloatingStat({
    required double top,
    double? left,
    double? right,
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required int delay, // Mock delay for animation concept
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(12),
        color: Colors.white.withOpacity(0.05),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: const TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1)),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
