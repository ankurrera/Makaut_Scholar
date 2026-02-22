import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

// Make sure these imports match your folder structure
import 'core/supabase_client.dart';
import 'services/auth_service.dart';
import 'services/offline_service.dart';
import 'features/auth/login/login_screen.dart';
import 'features/auth/signup/signup_screen.dart';
import 'features/profile/create_profile_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/navigation/main_nav_shell.dart';
import 'features/splash/splash_screen.dart';
import 'domain/repositories/billing_repository.dart';
import 'data/repositories/billing_repository_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load Environment Variables
  await dotenv.load(fileName: ".env");

  // 2. Initialize Supabase
  await SupabaseClientService.init();

  // 3. Initialize Offline Service
  await OfflineService().init();

  runApp(
    // 3. Setup Provider Scope
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider<BillingRepository>(
          create: (_) => BillingRepositoryImpl(),
          dispose: (_, repo) => repo.dispose(),
        ),
      ],
      child: const MakautScholarApp(),
    ),
  );
}

class MakautScholarApp extends StatelessWidget {
  const MakautScholarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAKAUT Scholar',
      debugShowCheckedModeBanner: false,

      // 4. Academic Themes (Light & Dark)
      themeMode: ThemeMode.system,
      
      // Light Theme
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: '.SF Pro Text',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C6FF6),
          brightness: Brightness.light,
          surface: const Color(0xFFFFFFFF),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F5F7),
        textTheme: const TextTheme(
          // Headlines / Titles — Semibold (600)
          headlineLarge: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5),
          headlineMedium: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.3),
          headlineSmall: TextStyle(fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontWeight: FontWeight.w500),
          titleSmall: TextStyle(fontWeight: FontWeight.w500),
          // Body — Regular (400) & Medium (500)
          bodyLarge: TextStyle(fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontWeight: FontWeight.w400),
          bodySmall: TextStyle(fontWeight: FontWeight.w400),
          // Labels — Medium (500)
          labelLarge: TextStyle(fontWeight: FontWeight.w500),
          labelMedium: TextStyle(fontWeight: FontWeight.w500),
          labelSmall: TextStyle(fontWeight: FontWeight.w500),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF4F5F7),
          foregroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF7C6FF6), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C6FF6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),

      // Dark Theme
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: '.SF Pro Text',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8E82FF),
          brightness: Brightness.dark,
          surface: const Color(0xFF0F1115),
          onSurface: const Color(0xFFF5F6FA),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F1115),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5),
          headlineMedium: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.3),
          headlineSmall: TextStyle(fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontWeight: FontWeight.w500),
          titleSmall: TextStyle(fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontWeight: FontWeight.w400),
          bodySmall: TextStyle(fontWeight: FontWeight.w400),
          labelLarge: TextStyle(fontWeight: FontWeight.w500),
          labelMedium: TextStyle(fontWeight: FontWeight.w500),
          labelSmall: TextStyle(fontWeight: FontWeight.w500),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF171A21),
          foregroundColor: Color(0xFFF5F6FA),
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF171A21),
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2A2F3A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF8E82FF), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8E82FF),
            foregroundColor: const Color(0xFFF5F6FA),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),

      // 5. Routes
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const MainNavShell(),
        '/create_profile': (context) => const CreateProfileScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}