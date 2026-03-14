import 'package:flutter/material.dart';
import 'dart:math' as math;

class DotLoadingIndicator extends StatefulWidget {
  final Color? color;
  final double size;

  const DotLoadingIndicator({
    super.key,
    this.color,
    this.size = 24.0,
  });

  @override
  State<DotLoadingIndicator> createState() => _DotLoadingIndicatorState();
}

class _DotLoadingIndicatorState extends State<DotLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // User Requirement: White in dark mode, Blue in light mode
    final defaultColor = isDark ? Colors.white : const Color(0xFF007BFF);
    final Color activeColor = widget.color ?? defaultColor;

    return SizedBox(
      width: widget.size * 1.5,
      height: widget.size * 1.5,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: List.generate(4, (index) {
              // Rotation radius is half of the total size
              final double radius = widget.size * 0.4;
              final double angle = (_controller.value * 2 * math.pi) + (index * math.pi / 2);
              
              // Pulsing effect for transparency and scale
              final double pulse = 0.5 + (0.5 * math.sin(_controller.value * 2 * math.pi + (index * math.pi / 4)));
              
              return Transform.translate(
                offset: Offset(
                  math.cos(angle) * radius,
                  math.sin(angle) * radius,
                ),
                child: Container(
                  width: (widget.size * 0.25) * (0.8 + 0.4 * pulse),
                  height: (widget.size * 0.25) * (0.8 + 0.4 * pulse),
                  decoration: BoxDecoration(
                    color: activeColor.withOpacity(0.3 + 0.7 * pulse),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
