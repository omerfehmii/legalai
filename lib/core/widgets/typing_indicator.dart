import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:legalai/core/theme/app_theme.dart';

// Yin Yang style orbiting dots indicator
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Slower rotation for Yin Yang feel
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Align to left, provide some padding
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double angle = _controller.value * 2.0 * math.pi;
            const double baseDotSize = 10.0; // Base size of the dots (Increased)
            const double minScale = 0.5;   // Minimum size factor
            const double maxScale = 1.5;   // Maximum size factor
            const double orbitRadius = 9.0;  // Radius of the orbit

            // Calculate scale based on sine wave (oscillates between minScale and maxScale)
            // scale1 grows when sin(angle) is positive, scale2 grows when sin(angle) is negative
            final double scale1 = minScale + (maxScale - minScale) * (1.0 + math.sin(angle)) / 2.0;
            final double scale2 = minScale + (maxScale - minScale) * (1.0 - math.sin(angle)) / 2.0;

            // Calculate positions based on angle and radius
            final double x1 = orbitRadius * math.cos(angle);
            final double y1 = orbitRadius * math.sin(angle);
            // Second dot is on the opposite side
            final double x2 = orbitRadius * math.cos(angle + math.pi); 
            final double y2 = orbitRadius * math.sin(angle + math.pi);

            // Calculate the required size for the container to hold the orbit + largest dot
            const double containerSize = 2 * orbitRadius + baseDotSize * maxScale;

            return SizedBox(
              width: containerSize,
              height: containerSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Dot 1 (Primary Color)
                  Transform.translate(
                    offset: Offset(x1, y1),
                    child: _buildDot(AppTheme.primaryColor, baseDotSize, scale1),
                  ),
                  // Dot 2 (Grey Color)
                  Transform.translate(
                    offset: Offset(x2, y2),
                    child: _buildDot(Colors.grey.shade400, baseDotSize, scale2),
            ),
          ],
        ),
            );
          },
        ),
      ),
    );
  }

  // Helper to build a scaled dot
  Widget _buildDot(Color color, double baseSize, double scale) {
    final scaledSize = baseSize * scale;
    // Ensure size doesn't become negative or too small due to floating point errors
    final finalSize = math.max(0.1, scaledSize); 
        return Container(
      width: finalSize,
      height: finalSize,
          decoration: BoxDecoration(
        color: color,
            shape: BoxShape.circle,
          ),
    );
  }
} 