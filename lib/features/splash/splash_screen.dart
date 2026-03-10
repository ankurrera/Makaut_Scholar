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

    // Safety guard: Don't let the splash hang forever if Supabase/Network is slow
    final safetyTimeout = Future.delayed(const Duration(seconds: 8));
    final minDelay = Future.delayed(const Duration(milliseconds: 1200));

    bool transitioned = false;

    void navigate(String route) {
      if (!mounted || transitioned) return;
      transitioned = true;
      Navigator.pushReplacementNamed(context, route);
    }

    // Attempt to check session and profile
    Future<void> performCheck() async {
      try {
        final sessionCheck = authService.currentSession;
        Map<String, dynamic>? profile;

        if (sessionCheck != null) {
          try {
            profile = await authService.getProfile();
          } catch (e) {
            debugPrint('Splash Profile Fetch Error: $e');
            // If we have a session but profile fetch fails (e.g. offline),
            // we still try to proceed or fall back to login if it's a critical error
          }

          await minDelay;

          if (profile != null &&
              profile['college_name'] != null &&
              profile['college_name'].toString().isNotEmpty) {
            navigate('/home');
          } else {
            // Even if profile is null but session exists, they might need to create a profile
            navigate('/create_profile');
          }
        } else {
          await minDelay;
          navigate('/login');
        }
      } catch (e) {
        debugPrint('Splash Check Error: $e');
        await minDelay;
        navigate('/login');
      }
    }

    // Race between normal check and safety timeout
    await Future.any([
      performCheck(),
      safetyTimeout.then((_) {
        if (!transitioned) {
          debugPrint('Splash safety timeout triggered');
          navigate('/login');
        }
      }),
    ]);
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
