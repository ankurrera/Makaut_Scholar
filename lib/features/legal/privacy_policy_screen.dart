import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../auth/login/login_screen.dart' show AuthTheme;

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bg      = isDark ? AuthTheme.darkBg      : AuthTheme.lightBg;
    final card    = isDark ? AuthTheme.darkSurface : AuthTheme.lightSurface;
    final border  = isDark ? AuthTheme.darkBorder  : AuthTheme.lightBorder;
    final text    = isDark ? AuthTheme.darkText     : AuthTheme.lightText;
    final subtext = isDark ? AuthTheme.darkSubtext  : AuthTheme.lightSubtext;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left_copy, color: text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            color: text,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Introduction',
              content: 'Welcome to ScholarX. We value your privacy and are committed to protecting your personal data. This Privacy Policy outlines how we collect, use, and safeguard your information when you use our mobile application.',
              isDark: isDark,
              card: card,
              border: border,
              text: text,
              subtext: subtext,
            ),
            _buildSection(
              title: 'Data Collection',
              content: 'We collect information that you provide directly to us when you create an account, such as your name, email address, and academic details (College, Department). We also collect your profile picture if you choose to upload one.',
              isDark: isDark,
              card: card,
              border: border,
              text: text,
              subtext: subtext,
            ),
            _buildSection(
              title: 'How We Use Your Data',
              content: 'Your data is used to provide and maintain our services, notify you about changes, and allow you to participate in interactive features. We do not sell your personal data to third parties.',
              isDark: isDark,
              card: card,
              border: border,
              text: text,
              subtext: subtext,
            ),
            _buildSection(
              title: 'Data Security',
              content: 'We implement industry-standard security measures to protect your data. Your academic records and profile information are stored securely using Supabase (PostgreSQL) with Row Level Security (RLS).',
              isDark: isDark,
              card: card,
              border: border,
              text: text,
              subtext: subtext,
            ),
            _buildSection(
              title: 'Third-Party Services',
              content: 'We use Supabase for authentication and database management. Some features may use Google Play Billing for premium content, which involves secure third-party payment processing.',
              isDark: isDark,
              card: card,
              border: border,
              text: text,
              subtext: subtext,
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Last Updated: March 4, 2026',
                style: TextStyle(
                  color: subtext,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required bool isDark,
    required Color card,
    required Color border,
    required Color text,
    required Color subtext,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AuthTheme.accent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: subtext,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
