import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final sessionCheck = authService.currentSession;
    
    // Very short delay to ensure the UI has time to frame once
    final minDelay = Future.delayed(const Duration(milliseconds: 1200));

    Map<String, dynamic>? profile;
    if (sessionCheck != null) {
      try {
        profile = await authService.getProfile();
      } catch (_) {}
    }

    await minDelay;
    
    if (!mounted) return;

    if (sessionCheck != null) {
      if (profile != null && profile['college_name'] != null && profile['college_name'].toString().isNotEmpty) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/create_profile');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Matching the logo's off-white background (#F7F5F2)
    const bgColor = Color(0xFFF7F5F2); 

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Static Logo Image
            Image.asset(
              'assets/scholarx_logo.png',
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 10),
            
            // Branding Text
            const Text(
              'SCHOLARX',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.0,
                color: Color(0xFF1E1E1E),
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'MAKAUT Edition',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}