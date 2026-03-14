import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart'; // Removed for security
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'features/notices/notice_board_screen.dart';
import 'features/notes/pdf_viewer_screen.dart';

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
import 'features/legal/privacy_policy_screen.dart';
import 'features/legal/about_screen.dart';
import 'services/monetization_service.dart';
import 'domain/repositories/billing_repository.dart';
import 'data/repositories/billing_repository_impl.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Critical Base Initializations (Sequential for debugging)
  try {
    debugPrint('Starting Firebase initialization...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));

    // Set background messaging handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    debugPrint('Firebase initialized.');
  } catch (e) {
    debugPrint('Base Init Warning: $e');
  }

  // 2. Supabase Initialization
  debugPrint('Starting Supabase initialization...');
  await SupabaseClientService.init().catchError((e) {
    debugPrint('Supabase Early Init Failed: $e');
  });
  debugPrint('Supabase initialization finished.');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MonetizationService()),
        Provider<BillingRepository>(
          create: (_) => BillingRepositoryImpl(),
          dispose: (_, repo) => repo.dispose(),
        ),
      ],
      child: const MakautScholarApp(),
    ),
  );
}

final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

class MakautScholarApp extends StatelessWidget {
  const MakautScholarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: globalNavigatorKey,
      title: 'ScholarX: MAKAUT Edition',
      debugShowCheckedModeBanner: false,

      // 4. Academic Themes (Light & Dark)
      themeMode: context.watch<ThemeProvider>().themeMode,

      // Light Theme
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'CallingCode',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE5252A),
          brightness: Brightness.light,
          surface: const Color(0xFFFFFFFF),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F5F7),
        textTheme: const TextTheme(
          // Headlines / Titles — Semibold (600)
          headlineLarge:
              TextStyle(fontFamily: 'NDOT', fontWeight: FontWeight.w600, letterSpacing: -0.5),
          headlineMedium:
              TextStyle(fontFamily: 'NDOT', fontWeight: FontWeight.w600, letterSpacing: -0.3),
          headlineSmall: TextStyle(fontFamily: 'NDOT', fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontFamily: 'NDOT', fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontFamily: 'NDOT', fontWeight: FontWeight.w500),
          titleSmall: TextStyle(fontFamily: 'NDOT', fontWeight: FontWeight.w500),
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
            borderSide: const BorderSide(color: Color(0xFFE5252A), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE5252A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),

      // Dark Theme
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'CallingCode',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE5252A),
          brightness: Brightness.dark,
          surface: const Color(0xFF000000),
          onSurface: const Color(0xFFFFFFFF),
        ),
        scaffoldBackgroundColor: const Color(0xFF000000),
        textTheme: const TextTheme(
          headlineLarge:
              TextStyle(fontFamily: 'NDOT', fontWeight: FontWeight.w600, letterSpacing: -0.5),
          headlineMedium:
              TextStyle(fontFamily: 'NDOT', fontWeight: FontWeight.w600, letterSpacing: -0.3),
          headlineSmall: TextStyle(fontFamily: 'NDOT', fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontFamily: 'NDOT', fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontFamily: 'NDOT', fontWeight: FontWeight.w500),
          titleSmall: TextStyle(fontFamily: 'NDOT', fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontWeight: FontWeight.w400),
          bodySmall: TextStyle(fontWeight: FontWeight.w400),
          labelLarge: TextStyle(fontWeight: FontWeight.w500),
          labelMedium: TextStyle(fontWeight: FontWeight.w500),
          labelSmall: TextStyle(fontWeight: FontWeight.w500),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
          foregroundColor: Color(0xFFFFFFFF),
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF121212),
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF222222)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5252A), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE5252A),
            foregroundColor: const Color(0xFFF5F6FA),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
        '/privacy': (context) => const PrivacyPolicyScreen(),
        '/about': (context) => const AboutScreen(),
        '/notices': (context) => const NoticeBoardScreen(),
        '/pdf_viewer': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>?;
          return PdfViewerScreen(
            url: args?['pdfUrl'] ?? args?['url'] ?? '',
            title: args?['title'] ?? 'Notice',
          );
        },
      },
    );
  }
}
