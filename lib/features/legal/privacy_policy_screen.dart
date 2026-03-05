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
    final accent  = AuthTheme.accent;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Premium App Bar ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: bg,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.arrow_left, color: text, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Privacy & Policy',
                style: TextStyle(
                  color: text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              background: Stack(
                children: [
                  // Abstract Background Pattern
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isDark ? 0.08 : 0.03),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 40,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isDark ? 0.05 : 0.02),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Image.asset(
                              isDark ? 'assets/darkmode.png' : 'assets/lightmode.png',
                              width: 40,
                              height: 40,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildIntro(text, subtext),
                const SizedBox(height: 32),
                
                _buildPolicyItem(
                  icon: Iconsax.user_tag,
                  title: 'Academic Identity',
                  description: 'We collect your Name, Email, College, and Department to create your academic profile on ScholarX.',
                  isDark: isDark, card: card, border: border, text: text, subtext: subtext, accent: accent,
                ),
                
                _buildPolicyItem(
                  icon: Iconsax.folder_2,
                  title: 'Content Access',
                  description: 'ScholarX accesses Notes, Syllabus, and PYQs. We track your "PRO" status for premium academic resources.',
                  isDark: isDark, card: card, border: border, text: text, subtext: subtext, accent: accent,
                ),
                
                _buildPolicyItem(
                  icon: Iconsax.gallery_edit,
                  title: 'Profile Customization',
                  description: 'If you upload an avatar, it is stored securely on Supabase Storage and associated with your ScholarX ID.',
                  isDark: isDark, card: card, border: border, text: text, subtext: subtext, accent: accent,
                ),
                
                _buildPolicyItem(
                  icon: Iconsax.security_safe,
                  title: 'Data Sovereignty',
                  description: 'Your data is protected by Row Level Security (RLS) in our PostgreSQL backend. You own your data.',
                  isDark: isDark, card: card, border: border, text: text, subtext: subtext, accent: accent,
                ),
                
                _buildPolicyItem(
                  icon: Iconsax.card_pos,
                  title: 'Secure Payments',
                  description: 'Premium purchases are handled via Google Play Billing. We do not store your credit card or sensitive financial data.',
                  isDark: isDark, card: card, border: border, text: text, subtext: subtext, accent: accent,
                ),
                
                _buildPolicyItem(
                  icon: Iconsax.trash,
                  title: 'Account Deletion',
                  description: 'You can delete your account permanently from the Profile screen. This erases all your records immediately.',
                  isDark: isDark, card: card, border: border, text: text, subtext: subtext, accent: accent,
                ),

                const SizedBox(height: 24),
                _buildFooter(subtext),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro(Color text, Color subtext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ScholarX: MAKAUT Edition',
          style: TextStyle(
            color: text,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Effective March 4, 2026. This policy describes how ScholarX handles your information to provide a better academic experience.',
          style: TextStyle(
            color: subtext,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
    required Color card,
    required Color border,
    required Color text,
    required Color subtext,
    required Color accent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: text,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: subtext,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(Color subtext) {
    return Center(
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 20),
          Text(
            'Built with transparency for the MAKAUT Community.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subtext.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ScholarX © 2026',
            style: TextStyle(
              color: subtext.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
