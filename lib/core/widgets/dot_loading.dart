import 'package:flutter/material.dart';

class DotLoadingIndicator extends StatefulWidget {
  final Color color;
  final double size;

  const DotLoadingIndicator({
    super.key,
    this.color = const Color(0xFFE5252A), // Nothing Red default
    this.size = 8.0,
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
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Calculate a staggered delay for each dot
            final double delay = index * 0.2;
            double opacity = 0.3;

            // The animation cycles from 0.0 to 1.0.
            // We create a wave effect where opacity spikes then fades.
            final double t = (_controller.value - delay) % 1.0;
            if (t >= 0 && t < 0.5) {
              // 0 to 0.5: opacity goes up to 1.0 and back down to 0.3
              opacity =
                  0.3 + (0.7 * (1.0 - (t * 4.0 - 1.0).abs().clamp(0.0, 1.0)));
            }

            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.size * 0.3),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
