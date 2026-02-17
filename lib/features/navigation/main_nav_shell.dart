import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'dart:ui'; // For ImageFilter
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../home/home_screen.dart';
import '../subjects/subjects_screen.dart';
import '../practice/practice_screen.dart';
import '../resources/resources_screen.dart';
import '../profile/profile_screen.dart';

class MainNavShell extends StatefulWidget {
  const MainNavShell({super.key});

  @override
  State<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends State<MainNavShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SubjectsScreen(),
    PracticeScreen(),
    ResourcesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2F2F7),
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2F2F7),
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: StaggeredSlideFade(
                delayMs: 300,
                child: _FloatingDock(
                  currentIndex: _currentIndex,
                  onTap: (index) => setState(() => _currentIndex = index),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingDock extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingDock({required this.currentIndex, required this.onTap});

  @override
  State<_FloatingDock> createState() => _FloatingDockState();
}

class _FloatingDockState extends State<_FloatingDock> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _prevIndex = 0;

  static const double _dockHeight = 70;
  static const double _indicatorSize = 52;

  // Outlined (inactive) and bold (active) icon pairs
  static const _icons = [
    [Iconsax.home_1, Iconsax.home_1_copy],       // Home
    [Iconsax.book_1, Iconsax.book_1_copy],        // Subjects
    [Iconsax.task_square, Iconsax.task_square_copy], // Practice
    [Iconsax.folder, Iconsax.folder_copy],        // Resources
    [Iconsax.profile_circle, Iconsax.profile_circle_copy], // Profile
  ];

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.currentIndex;
    _controller = AnimationController(
        duration: const Duration(milliseconds: 600), 
        vsync: this
    );
    // Use elasticOut for smooth bounce
    _animation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward(from: 1.0); // Start settled
  }

  @override
  void didUpdateWidget(_FloatingDock oldWidget) {
    if (widget.currentIndex != oldWidget.currentIndex) {
      _prevIndex = oldWidget.currentIndex;
      _controller.forward(from: 0.0);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), // Apple-style Blur
          child: Container(
            height: _dockHeight,
            constraints: const BoxConstraints(maxWidth: 400), // Limit max width on tablets
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.6), // Adaptive Glass
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: -5,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate dynamic width available for items
                final availableWidth = constraints.maxWidth; 
                final itemWidth = availableWidth / _icons.length;

                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Layer 1: Gooey Liquid Indicator
                    AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                            // Interpolate Position
                            final double t = _animation.value;
                            final double startX = (_prevIndex * itemWidth) + (itemWidth - _indicatorSize) / 2;
                            final double endX = (widget.currentIndex * itemWidth) + (itemWidth - _indicatorSize) / 2;
                            final double currentX = lerpDouble(startX, endX, t)!;
                            
                            // Stretch Effect (based on linear progress)
                            final double linearT = _controller.value;
                            // Use sine wave for stretch: 0 -> 1 -> 0
                            const double stretchFactor = 20.0;
                            final double stretch = sin(linearT * pi) * stretchFactor;
                            
                            // Avoid negative width/height
                            final double width = _indicatorSize + stretch;
                            final double height = _indicatorSize - (stretch * 0.4);

                            return Positioned(
                                left: currentX - (stretch / 2),
                                width: width,
                                height: height,
                                child: Container(
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF7F56D9),
                                        borderRadius: BorderRadius.circular(30), // Pill shape for stretch
                                        boxShadow: [
                                            BoxShadow(
                                                color: const Color(0xFF7F56D9).withValues(alpha: 0.4),
                                                blurRadius: 12 + (stretch * 0.5), // Glow pulses with stretch
                                                spreadRadius: 2,
                                            )
                                        ],
                                    ),
                                ),
                            );
                        },
                    ),

                    // Layer 2: Icons
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(_icons.length, (index) {
                        final isActive = widget.currentIndex == index;
                        return GestureDetector(
                          onTap: () => widget.onTap(index),
                          behavior: HitTestBehavior.opaque, // Ensure tap works on transparent area
                          child: SizedBox(
                            width: itemWidth,
                            height: _dockHeight,
                            child: Center(
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 200),
                                scale: isActive ? 1.1 : 1.0,
                                child: Icon(
                                  isActive ? _icons[index][1] : _icons[index][0],
                                  color: isActive 
                                      ? Colors.white 
                                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                  size: 26,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
