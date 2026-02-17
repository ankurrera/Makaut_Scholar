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
    // Add a small delay for better UX (so the splash doesn't just flicker)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final session = authService.currentSession;

    if (session != null) {
      // Check if profile exists and is complete
      final profile = await authService.getProfile();
      if (!mounted) return;
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
    const backgroundColor = Color(0xFF0A0A0A);
    const primaryAccent = Color(0xFFCCFF00); // Lime Green

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1C1C1E),
                boxShadow: [
                   BoxShadow(
                      color: primaryAccent.withValues(alpha: 0.2),
                      blurRadius: 40,
                      spreadRadius: 10,
                   ),
                ],
              ),
              child: const Icon(Icons.school_rounded, size: 80, color: primaryAccent),
            ),
            const SizedBox(height: 32),
            const Text(
              "MAKAUT Scholar",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
             const SizedBox(height: 8),
             Text(
              "Your Academic Companion",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: primaryAccent),
          ],
        ),
      ),
    );
  }
}