import 'package:flutter/material.dart';
import 'package:legalai/core/theme/app_theme.dart';

// Simple typing indicator with animated dots
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
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Align to left like an AI message bubble
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 5, top: 5, right: 120), // Margin to keep it left-aligned
        decoration: BoxDecoration(
          color: Colors.white, // Match AI bubble color
          borderRadius: const BorderRadius.only( // Match AI bubble shape
             topLeft: Radius.circular(20),
             topRight: Radius.circular(20),
             bottomLeft: Radius.circular(4),
             bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(delay: 0),
            const SizedBox(width: 4),
            _buildDot(delay: 0.4),
            const SizedBox(width: 4),
            _buildDot(delay: 0.8),
          ],
        ),
      ),
    );
  }

  // Helper to build animated dots
  Widget _buildDot({required double delay}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Simple bounce effect using opacity
        final double opacity = (((_controller.value + delay) % 1.0) < 0.5)
            ? ((_controller.value + delay) % 0.5) * 2 // Fading in
            : 1.0 - (((_controller.value + delay) % 0.5) * 2); // Fading out

        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            // Use primary color for dots, adjust opacity
            color: AppTheme.primaryColor.withOpacity(0.3 + (opacity * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
} 