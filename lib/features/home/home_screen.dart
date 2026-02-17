import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    const backgroundColor = Color(0xFF051105); // Deep Dark Green
    const primaryAccent = Color(0xFFCCFF00); // Lime Green
    const cardDark = Color(0xFF1C1C1E);
    const cardWhite = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F2610), // Dark Forest Green top
              Color(0xFF000000), // Black bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header (0ms delay)
                StaggeredSlideFade(
                  delayMs: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=11'),
                            backgroundColor: Colors.grey[800],
                          ),
                          const Spacer(),
                          _buildIconButton(Icons.download_rounded, () {}),
                          const SizedBox(width: 8),
                          _buildIconButton(Icons.settings_outlined, () => _logout(context)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Hey, $_userName",
                        style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                      ),
                      const Text(
                        "Welcome Back",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // 2. Bento Grid
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  // Notes (100ms)
                                  StaggeredSlideFade(
                                    delayMs: _baseDelay * 1,
                                    child: _buildBentoCard(
                                      height: 180,
                                      color: primaryAccent,
                                      title: "Notes",
                                      icon: Icons.auto_stories,
                                      iconColor: Colors.black,
                                      textColor: Colors.black,
                                      isLargeIcon: true,
                                      onTap: () {}, // Navigate
                                      decorationWidget: Positioned(
                                        bottom: 10, left: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text("Unit-wise Q&A", style: TextStyle(fontSize: 10, color: Colors.black)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Continue (200ms)
                                  StaggeredSlideFade(
                                    delayMs: _baseDelay * 2,
                                    child: _buildBentoCard(
                                      height: 100,
                                      color: cardWhite,
                                      title: "Continue",
                                      icon: Icons.bar_chart,
                                      iconColor: Colors.black,
                                      textColor: Colors.black,
                                      onTap: () {},
                                      child: Column( // Custom child for progress
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("Continue", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                                          const SizedBox(height: 4),
                                          const Text("DBMS - Unit 2", style: TextStyle(fontSize: 10, color: Colors.black54)),
                                          const Spacer(),
                                          const Text("40% Completed", style: TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          const AnimatedProgressBar(percent: 0.4),
                                        ],
                                      ),
                                    ),
                                  ),
                                   const SizedBox(height: 16),
                                  // Upgrade (250ms) - Pulsing
                                  StaggeredSlideFade(
                                    delayMs: _baseDelay * 3, // slightly later
                                    child: PulseDecoration(
                                      child: _buildBentoCard(
                                        height: 100, 
                                        color: const Color(0xFFD4FF00), 
                                        title: "Upgrade",
                                        icon: Icons.diamond,
                                        iconColor: Colors.black,
                                        textColor: Colors.black,
                                        onTap: () {},
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Right Column
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  // PYQ (150ms) - Interleaved
                                  StaggeredSlideFade(
                                    delayMs: (_baseDelay * 1.5).toInt(),
                                    child: _buildBentoCard(
                                      height: 100,
                                      color: cardDark,
                                      title: "PYQ",
                                      icon: Icons.history_edu,
                                      iconColor: Colors.white,
                                      textColor: Colors.white,
                                      onTap: () {},
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Important (250ms)
                                  StaggeredSlideFade(
                                    delayMs: (_baseDelay * 2.5).toInt(),
                                    child: _buildBentoCard(
                                      height: 100,
                                      color: cardWhite,
                                      title: "Important",
                                      icon: Icons.local_fire_department_rounded,
                                      iconColor: Colors.orangeAccent,
                                      textColor: Colors.black,
                                      onTap: () {},
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Subjects (350ms)
                                  StaggeredSlideFade(
                                    delayMs: (_baseDelay * 3.5).toInt(),
                                    child: _buildBentoCard(
                                      height: 180,
                                      color: cardDark,
                                      title: "Subjects",
                                      icon: Icons.library_books_outlined,
                                      iconColor: const Color(0xFF69F0AE),
                                      textColor: Colors.white,
                                      isLargeIcon: true,
                                      onTap: () {},
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // 3. Syllabus Banner (400ms)
                        StaggeredSlideFade(
                          delayMs: _baseDelay * 4,
                          child: ScaleButton(
                            onTap: () {},
                            child: Container(
                              height: 80,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: cardWhite,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Syllabus",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        "Official MAKAUT Syllabus",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.class_outlined, size: 40, color: Colors.blueAccent),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8), // Explicit padding for touch area
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.grey[400], size: 20),
      ),
    );
  }

  Widget _buildBentoCard({
    required double height,
    required Color color,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
    bool isLargeIcon = false,
    String? subtitle,
    Widget? decorationWidget,
    Widget? child, // Optional custom child override
  }) {
    // If custom child is provided (like for Continue card), use it.
    // Otherwise build standard layout.
    
    Widget content = child ?? Stack(
      children: [
        // Title
        Positioned(
          top: 0,
          left: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w600, 
                  color: textColor,
                ),
              ),
              if (subtitle != null) ...[
                 const SizedBox(height: 4),
                 Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: textColor.withValues(alpha: 0.7),
                    height: 1.2,
                  ),
                 ),
              ]
            ],
          ),
        ),
        
        // Icon
        Positioned(
          bottom: 0,
          right: 0,
          child: isLargeIcon 
            ? Icon(icon, size: 60, color: iconColor.withValues(alpha: 0.8))
            : Icon(icon, size: 32, color: iconColor),
        ),
        
        if (decorationWidget != null) decorationWidget,
      ],
    );

    return ScaleButton(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2), // Subtle shadow
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: content,
      ),
    );
  }
}

// --- Animation Widgets ---

class ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Duration duration;
  final double scaleDown;

  const ScaleButton({
    super.key,
    required this.child,
    required this.onTap,
    this.duration = const Duration(milliseconds: 120),
    this.scaleDown = 0.97,
  });

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
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
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

class StaggeredSlideFade extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final Duration duration;

  const StaggeredSlideFade({
    super.key,
    required this.child,
    required this.delayMs,
    this.duration = const Duration(milliseconds: 250),
  });

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
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

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
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

class PulseDecoration extends StatefulWidget {
  final Widget child;
  const PulseDecoration({super.key, required this.child});

  @override
  State<PulseDecoration> createState() => _PulseDecorationState();
}

class _PulseDecorationState extends State<PulseDecoration> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Pulse every 5 seconds
    _startPulseLoop();
  }

  void _startPulseLoop() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        await _controller.forward();
        await _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: widget.child,
    );
  }
}

class AnimatedProgressBar extends StatefulWidget {
  final double percent; // 0.0 to 1.0
  const AnimatedProgressBar({super.key, required this.percent});

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(3),
          ),
          child: Stack(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: widget.percent),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                builder: (context, value, _) {
                  return Container(
                    width: constraints.maxWidth * value,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFF00), // Lime
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}