import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class ModernFolder extends StatelessWidget {
  final Widget? child;
  final Color color;
  final String? label;
  final VoidCallback? onTap;
  final bool showSpeckles;

  const ModernFolder({
    super.key,
    this.child,
    required this.color,
    this.label,
    this.onTap,
    this.showSpeckles = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            CustomPaint(
              size: Size.infinite,
              painter: _FolderPainter(
                color: color,
                isDark: isDark,
                showSpeckles: showSpeckles,
              ),
            ),
            if (child != null)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 32, 12, 12),
                  child: child!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FolderPainter extends CustomPainter {
  final Color color;
  final bool isDark;
  final bool showSpeckles;

  _FolderPainter({
    required this.color, 
    required this.isDark,
    required this.showSpeckles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = 16.0; // Sharp but smooth enough base radius
    
    // 1. Back Sheet (Tab B side) - Darker and softer
    final backPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(w * 0.5, 0),
        Offset(w * 0.5, h),
        [
          color.withValues(alpha: 0.7),
          color.withValues(alpha: 0.9),
        ],
      )
      ..style = PaintingStyle.fill;

    // Use a simpler approach: Layered RRects + Wave
    final backBase = RRect.fromLTRBR(0, 4, w, h, Radius.circular(r));
    
    // Path for the Back Tab "B"
    final backTabPath = Path();
    backTabPath.moveTo(w * 0.45, 12);
    backTabPath.quadraticBezierTo(w * 0.55, 0, w * 0.75, 0); // Tab rise
    backTabPath.lineTo(w - r, 0);
    backTabPath.quadraticBezierTo(w, 0, w, r);
    backTabPath.lineTo(w, h - r);
    backTabPath.lineTo(0, h - r);
    backTabPath.close();

    canvas.drawRRect(backBase, backPaint);
    canvas.drawPath(backTabPath, backPaint);

    // 2. Front Sheet (Tab A side) - Main visible area
    final frontPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(w, h),
        [
          color.withValues(alpha: 1.0),
          color.withValues(alpha: 0.85),
        ],
      )
      ..style = PaintingStyle.fill;
    
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);
    
    // Front Sheet Path: Structured base + Tab A wave
    final frontPath = Path();
    // Start at mid-left
    frontPath.moveTo(0, r + 12);
    frontPath.quadraticBezierTo(0, 12, r, 12); // Corner
    frontPath.lineTo(w * 0.35, 12); // Top edge of tab base
    frontPath.quadraticBezierTo(w * 0.45, 12, w * 0.55, 24); // Wave down transition
    frontPath.lineTo(w - r, 24);
    frontPath.quadraticBezierTo(w, 24, w, 24 + r);
    frontPath.lineTo(w, h - r);
    frontPath.quadraticBezierTo(w, h, w - r, h);
    frontPath.lineTo(r, h);
    frontPath.quadraticBezierTo(0, h, 0, h - r);
    frontPath.close();

    canvas.drawPath(frontPath, shadowPaint);
    canvas.drawPath(frontPath, frontPaint);

    // 3. Speckled Texture (Selective to front)
    if (showSpeckles) {
      final random = math.Random(color.value);
      final specklePaint = Paint()
        ..color = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill;
      
      for (int i = 0; i < 150; i++) {
        final x = random.nextDouble() * w;
        final y = random.nextDouble() * h;
        if (frontPath.contains(Offset(x, y))) {
          canvas.drawCircle(Offset(x, y), random.nextDouble() * 1.5, specklePaint);
        }
      }
    }
    
    // 4. Subtle Border/Rim light to define edges
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(frontPath, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _FolderPainter oldDelegate) => 
      oldDelegate.color != color || oldDelegate.isDark != isDark;
}
