import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'dart:ui'; // For ImageFilter
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../home/home_screen.dart';
import '../subjects/subjects_screen.dart';
import '../practice/practice_screen.dart';
import '../resources/resources_screen.dart';

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
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? const Color(0xFF0F1115) : const Color(0xFFF4F5F7),
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F1115) : const Color(0xFFF4F5F7),
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
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
  late Animation<double> _slideAnimation;
  int _prevIndex = 0;

  static const double _dockHeight = 56;
  static const double _indicatorSize = 44;

  static const _icons = [
    [Iconsax.home_1, Iconsax.home_1_copy],
    [Iconsax.book_1, Iconsax.book_1_copy],
    [Iconsax.task_square, Iconsax.task_square_copy],
    [Iconsax.folder, Iconsax.folder_copy],
  ];

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.currentIndex;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(_FloatingDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _prevIndex = oldWidget.currentIndex;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Liquid glass palette
    final indicatorColor = isDark 
      ? const Color(0xFF8E82FF) 
      : const Color(0xFF7C6FF6);
    final activeIconColor = Colors.white;
    final inactiveIconColor = isDark 
      ? const Color(0xFF9AA0A6) 
      : const Color(0xFF8E8E93);

    final radius = BorderRadius.circular(_dockHeight / 2);

    return Center(
      child: Container(
        height: _dockHeight,
        constraints: const BoxConstraints(maxWidth: 230),
        decoration: BoxDecoration(
          borderRadius: radius,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              decoration: BoxDecoration(
                // Ultra-thin glass fill — mostly transparent
                color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.45),
                borderRadius: radius,
              ),
              child: Container(
                // Gradient border + inner shine layer
                decoration: BoxDecoration(
                  borderRadius: radius,
                  // Gradient border: bright top edge, dim bottom — glass rim reflection
                  border: Border.all(
                    color: Colors.transparent,
                    width: 1.0,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                      ? [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white.withValues(alpha: 0.04),
                          Colors.white.withValues(alpha: 0.08),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.8),
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.35),
                        ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: Container(
                  // Inner glass body
                  margin: const EdgeInsets.all(1.0), // Creates the gradient border effect
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_dockHeight / 2 - 1),
                    color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.35),
                    // Top-edge shine highlight
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                        ? [
                            Colors.white.withValues(alpha: 0.10),
                            Colors.white.withValues(alpha: 0.03),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.55),
                            Colors.white.withValues(alpha: 0.20),
                          ],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final itemWidth = availableWidth / _icons.length;

                  return Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Gooey Liquid Indicator
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final double t = _slideAnimation.value;
                          final double startX = (_prevIndex * itemWidth) + (itemWidth - _indicatorSize) / 2;
                          final double endX = (widget.currentIndex * itemWidth) + (itemWidth - _indicatorSize) / 2;
                          final double currentX = lerpDouble(startX, endX, t)!;

                          // Stretch effect using sine wave
                          final double linearT = _controller.value;
                          const double stretchFactor = 16.0;
                          double stretch = sin(linearT * pi) * stretchFactor;

                          // Taper stretch near edges so it fades out smoothly
                          final double edgeMargin = _indicatorSize * 0.5;
                          final double distToLeft = currentX;
                          final double distToRight = availableWidth - currentX - _indicatorSize;
                          final double edgeFade = (distToLeft.clamp(0, edgeMargin) / edgeMargin)
                              .clamp(0.0, 1.0) *
                              (distToRight.clamp(0, edgeMargin) / edgeMargin)
                              .clamp(0.0, 1.0);
                          stretch *= edgeFade;

                          // Raw position & size
                          double rawLeft = currentX - (stretch / 2);
                          double width = _indicatorSize + stretch;
                          final double height = _indicatorSize - (stretch * 0.35);

                          // Hard boundary clamping as safety net
                          if (rawLeft < 0) {
                            width += rawLeft;
                            rawLeft = 0;
                          }
                          if (rawLeft + width > availableWidth) {
                            width = availableWidth - rawLeft;
                          }

                          return Positioned(
                            left: rawLeft,
                            width: width.clamp(_indicatorSize * 0.5, availableWidth),
                            height: height,
                            child: Container(
                              decoration: BoxDecoration(
                                color: indicatorColor,
                                borderRadius: BorderRadius.circular(26),

                              ),
                            ),
                          );
                        },
                      ),

                      // Icons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(_icons.length, (index) {
                          final isActive = widget.currentIndex == index;
                          return GestureDetector(
                            onTap: () => widget.onTap(index),
                            behavior: HitTestBehavior.opaque,
                            child: SizedBox(
                              width: itemWidth,
                              height: _dockHeight,
                              child: Center(
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: isActive ? 0.0 : 1.0, end: isActive ? 1.0 : 0.0),
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: 1.0 + (value * 0.08), // Subtle 8% scale
                                      child: Icon(
                                        isActive ? _icons[index][1] : _icons[index][0],
                                        color: Color.lerp(inactiveIconColor, activeIconColor, value),
                                        size: 22,
                                      ),
                                    );
                                  },
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
          ),
        ),
      ),
    );
  }
}
