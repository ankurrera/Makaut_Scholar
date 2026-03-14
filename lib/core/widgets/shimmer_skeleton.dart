import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final bool isNdot;

  const ShimmerSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.isNdot = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F2),
      highlightColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// A common skeleton for list tiles
  static Widget listTile({required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          ShimmerSkeleton(
            width: 52,
            height: 52,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerSkeleton(width: 100, height: 12),
                const SizedBox(height: 8),
                const ShimmerSkeleton(width: double.infinity, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A common skeleton for grid items
  static Widget gridItem({required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShimmerSkeleton(
          width: double.infinity,
          height: 120,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        const SizedBox(height: 12),
        const ShimmerSkeleton(width: 80, height: 12),
        const SizedBox(height: 8),
        const ShimmerSkeleton(width: 120, height: 16),
      ],
    );
  }
}
