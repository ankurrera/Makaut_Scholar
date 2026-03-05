import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../auth/login/login_screen.dart' show AuthTheme;

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '...';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = info.version;
          _buildNumber = info.buildNumber;
        });
      }
    } catch (e) {
      debugPrint("Error loading package info: $e");
      if (mounted) {
        setState(() {
          _version = "1.1.1"; // Fallback to current version
          _buildNumber = "8";
        });
      }
    }
  }

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
          // ── Premium Header ────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
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
              background: Stack(
                children: [
                   // Abstract Background Circles
                  Positioned(
                    top: -60,
                    right: -40,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isDark ? 0.07 : 0.03),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: -20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isDark ? 0.04 : 0.02),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Hero(
                          tag: 'app_logo_about',
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: Image.asset(
                              isDark ? 'assets/darkmode.png' : 'assets/lightmode.png',
                              width: 40,
                              height: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ScholarX',
                          style: TextStyle(
                            color: text,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'MAKAUT EDITION',
                          style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── App Mission & Details ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionTitle('MISSION', subtext),
                const SizedBox(height: 12),
                _buildMissionCard(card, border, text, subtext),
                
                const SizedBox(height: 32),
                _buildSectionTitle('DEVELOPMENT', subtext),
                const SizedBox(height: 12),
                _buildTeamCard(card, border, text, subtext, accent),
                
                const SizedBox(height: 32),
                _buildSectionTitle('APP INFO', subtext),
                const SizedBox(height: 12),
                _buildInfoGrid(card, border, text, subtext, accent),
                
                const SizedBox(height: 48),
                _buildSocialFooter(subtext, accent),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color subtext) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: subtext.withValues(alpha: 0.6),
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildMissionCard(Color card, Color border, Color text, Color subtext) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Empowering Students',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: text),
          ),
          const SizedBox(height: 8),
          Text(
            'ScholarX is built specifically for the MAKAUT community. Our goal is to provide seamless access to high-quality academic resources, organized notes, and essential exam tools in one unified platform.',
            style: TextStyle(fontSize: 14, color: subtext, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(Color card, Color border, Color text, Color subtext, Color accent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.code, color: accent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Orbit Innovations',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: text),
                ),
                Text(
                  'Driving academic excellence through technology.',
                  style: TextStyle(fontSize: 13, color: subtext),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(Color card, Color border, Color text, Color subtext, Color accent) {
    return Column(
      children: [
        _infoTile(Iconsax.info_circle, 'Version', '$_version.$_buildNumber', card, border, text, subtext, accent),
        const SizedBox(height: 12),
        _infoTile(Iconsax.verify, 'Build Type', 'Production', card, border, text, subtext, accent),
        const SizedBox(height: 12),
        _infoTile(Iconsax.calendar_1, 'Last Updated', 'March 2026', card, border, text, subtext, accent),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value, Color card, Color border, Color text, Color subtext, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent.withValues(alpha: 0.7), size: 18),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(fontSize: 14, color: subtext, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 14, color: text, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSocialFooter(Color subtext, Color accent) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialIcon(Iconsax.global, accent),
            const SizedBox(width: 20),
            _socialIcon(Iconsax.instagram, accent),
            const SizedBox(width: 20),
            _socialIcon(Iconsax.link, accent),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'ScholarX © 2026 Orbit Innovations',
          style: TextStyle(fontSize: 12, color: subtext.withValues(alpha: 0.5), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          'Made with ❤️ in India',
          style: TextStyle(fontSize: 11, color: subtext.withValues(alpha: 0.3)),
        ),
      ],
    );
  }

  Widget _socialIcon(IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: accent, size: 20),
    );
  }
}
