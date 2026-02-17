
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'dart:ui'; // For ImageFilter
import '../../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  String _userName = 'Scholar';
  String? _profileName;

  // Animation constants
  static const int _baseDelay = 100;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final profile = await authService.getProfile();

    if (mounted) {
      setState(() {
        if (profile != null && profile['name'] != null) {
          _profileName = profile['name'];
          _userName = _profileName!.split(' ').first;
        } else if (user?.userMetadata?['name'] != null) {
          _userName = user!.userMetadata!['name'].split(' ').first;
        }
      });
    }
  }

  void _logout(BuildContext context) async {
    await Provider.of<AuthService>(context, listen: false).signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dynamic Palette based on Theme
    final bgTop = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFF2F2F7);
    final bgBottom = isDark ? const Color(0xFF121212) : const Color(0xFFFFFFFF);
    
    // Accents: Lighter for Dark Mode (pop against dark), Darker for Light Mode (readable against light)
    final accentLavender = isDark ? const Color(0xFFD0BCFF) : const Color(0xFF6750A4);
    final accentMint = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
    final accentPink = isDark ? const Color(0xFFF06292) : const Color(0xFFC2185B);
    final accentBlue = isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0);
    final accentOrange = isDark ? const Color(0xFFFFB74D) : const Color(0xFFEF6C00);



    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgTop, bgBottom],
          stops: [0.0, 0.8],
        ),
      ),
      child: Stack(
        children: [
          // Ambient Background Glows (Simulated)
          Positioned(
            top: -100, left: -50,
            child: _buildAmbientGlow(accentLavender.withValues(alpha: 0.15)),
          ),
          Positioned(
            bottom: 100, right: -50,
            child: _buildAmbientGlow(accentBlue.withValues(alpha: 0.1)),
          ),

          // Main Scrollable Content
          SafeArea(
            bottom: false,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Bottom padding for dock
              children: [
                // 1. Hero Section
                StaggeredSlideFade(
                  delayMs: 0,
                  child: _buildHeroSection(_userName, context),
                ),

                const SizedBox(height: 32),

                // 2. Feature Grid (Bento)
                StaggeredSlideFade(
                  delayMs: _baseDelay,
                  child: _buildFeatureGrid(accentLavender, accentMint, accentPink, accentBlue, accentOrange),
                ),

                const SizedBox(height: 24),

                // 3. Analytics Section
                StaggeredSlideFade(
                  delayMs: _baseDelay * 2,
                  child: _buildAnalyticsSection(accentBlue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientGlow(Color color) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 100, spreadRadius: 50),
        ],
      ),
    );
  }

  Widget _buildHeroSection(String name, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Row(
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(4),
          shape: BoxShape.circle,
          child: const CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Good Evening,",
              style: TextStyle(fontSize: 14, color: subTextColor),
            ),
            Text(
              name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const Spacer(),
        GlassIconButton(
          icon: Iconsax.notification,
          onTap: () {},
        ),
        const SizedBox(width: 12),
        GlassIconButton(
          icon: Iconsax.setting_2,
          onTap: () => _logout(context),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid(Color lavender, Color mint, Color pink, Color blue, Color orange) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Column(
      children: [
        // Row 1: Notes (Large) + Stacked Cards
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large Notes Card
            Expanded(
              flex: 3,
              child: ScaleButton(
                onTap: () {},
                child: GlassCard(
                  height: 220,
                  color: lavender.withValues(alpha: 0.1),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20, bottom: -20,
                        child: Icon(Iconsax.book_1, size: 100, color: lavender.withValues(alpha: 0.2)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: lavender.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Iconsax.book, color: lavender, size: 24),
                            ),
                            const Spacer(),
                            Text(
                              "Academic Notes",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "45 Files • Updated 2h ago",
                              style: TextStyle(fontSize: 12, color: subTextColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Stacked Cards
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  // PYQ
                  _buildSmallGlassCard(
                    title: "PYQ Bank",
                    icon: Iconsax.document_text,
                    color: mint,
                    height: 100,
                  ),
                  const SizedBox(height: 16),
                  // Important
                  _buildSmallGlassCard(
                    title: "Exam Focus",
                    icon: Iconsax.star,
                    color: pink,
                    height: 104, // To align heights (220 total - 16 gap = 204 / 2 = 102~104)
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Row 2: Syllabus (New Button)
        ScaleButton(
          onTap: () {},
          child: GlassCard(
            height: 80,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: orange.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Iconsax.book_saved, color: orange, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Syllabus",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                      ),
                      Text(
                        "View Course Structure",
                        style: TextStyle(fontSize: 12, color: subTextColor),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(Iconsax.arrow_right_3, color: isDark ? Colors.white54 : Colors.black45, size: 24),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Row 3: Progress
        ScaleButton(
          onTap: () {},
          child: GlassCard(
            height: 80,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 40, height: 40,
                    child: CircularProgressIndicator(
                      value: 0.65,
                      strokeWidth: 4,
                      backgroundColor: Colors.grey.withValues(alpha: 0.1),
                      color: blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Continue Studying",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                      ),
                      Text(
                        "DBMS Unit 3 • 65% Done",
                        style: TextStyle(fontSize: 12, color: blue),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(Iconsax.play_circle, color: blue, size: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallGlassCard({required String title, required IconData icon, required Color color, required double height}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return ScaleButton(
      onTap: () {},
      child: GlassCard(
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const Spacer(),
              Text(
                title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection(Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            "Weekly Activity",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          height: 140,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Circular Chart
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80, height: 80,
                            child: CircularProgressIndicator(
                              value: 0.75,
                              strokeWidth: 8,
                              strokeCap: StrokeCap.round,
                                backgroundColor: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
                              color: accentColor,
                            ),
                          ),
                          Text(
                            "75%",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: accentColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Bar Chart (Simulated)
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar(0.4, accentColor),
                      _buildBar(0.6, accentColor),
                      _buildBar(0.3, accentColor),
                      _buildBar(0.9, accentColor),
                      _buildBar(0.5, accentColor),
                      _buildBar(0.2, accentColor),
                      _buildBar(0.7, accentColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBar(double heightFactor, Color color) {
    return FractionallySizedBox(
      heightFactor: heightFactor * 0.8, // Scale down to fit
      child: Container(
        width: 6,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

// --- Reusable Glass Widgets ---

class GlassCard extends StatelessWidget {
  final double? height;
  final double? width;
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const GlassCard({
    super.key,
    this.height,
    this.width,
    required this.child,
    this.color, this.padding
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      height: height,
      width: width,
      color: color,
      child: child,
    );
  }
}

class GlassContainer extends StatelessWidget {
  final double? height;
  final double? width;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BoxShape shape;
  final Color? color;

  const GlassContainer({
    super.key,
    this.height,
    this.width,
    required this.child,
    this.padding,
    this.shape = BoxShape.rectangle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: shape == BoxShape.circle ? BorderRadius.zero : BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), // Heavy Apple-style Blur
        child: Container(
          height: height,
          width: width,
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? (Theme.of(context).brightness == Brightness.dark 
                ? Colors.white.withValues(alpha: 0.12) 
                : Colors.white.withValues(alpha: 0.85)), // More solid White for Light Mode to pop against grey/white bg
            shape: shape,
            borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(32),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white.withValues(alpha: 0.2) 
                  : Colors.black.withValues(alpha: 0.1), // Slightly darker border for Light Mode
              width: 0.5,
            ),
            boxShadow: Theme.of(context).brightness == Brightness.dark ? [] : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), // Subtle shadow for lift
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const GlassIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScaleButton(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        shape: BoxShape.circle,
        child: Icon(icon, color: isDark ? Colors.white : Colors.black, size: 20),
      ),
    );
  }
}


// --- Animations (Reused from Previous) ---

class ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const ScaleButton({super.key, required this.child, required this.onTap});

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

class StaggeredSlideFade extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const StaggeredSlideFade({super.key, required this.child, required this.delayMs});

  @override
  State<StaggeredSlideFade> createState() => _StaggeredSlideFadeState();
}

class _StaggeredSlideFadeState extends State<StaggeredSlideFade> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: SlideTransition(position: _slide, child: widget.child));
  }
}
