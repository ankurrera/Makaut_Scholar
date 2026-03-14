import 'package:flutter/material.dart';

class SolidFolder extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final double tabHeight;
  final Widget? child;
  final VoidCallback? onTap;

  const SolidFolder({
    super.key,
    required this.color,
    this.borderColor = Colors.transparent,
    this.tabHeight = 10.0,
    this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: _SolidFolderPainter(
          color: color,
          borderColor: borderColor,
          tabHeight: tabHeight,
        ),
        child: child,
      ),
    );
  }
}

class _SolidFolderPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double tabHeight;

  _SolidFolderPainter({
    required this.color,
    required this.borderColor,
    required this.tabHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.width * 0.15;
    final double tabW = size.width * 0.40;

    final path = Path();
    path.moveTo(r, 0);
    path.lineTo(tabW - r, 0);
    path.quadraticBezierTo(tabW - (r / 2), 0, tabW, tabHeight / 2);
    path.quadraticBezierTo(tabW + (r / 2), tabHeight, tabW + r, tabHeight);

    path.lineTo(size.width - r, tabHeight);
    path.quadraticBezierTo(size.width, tabHeight, size.width, tabHeight + r);

    path.lineTo(size.width, size.height - r);
    path.quadraticBezierTo(
        size.width, size.height, size.width - r, size.height);

    path.lineTo(r, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - r);

    path.lineTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.close();

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    if (borderColor != Colors.transparent) {
      final strokePaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SolidFolderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.tabHeight != tabHeight;
  }
}
