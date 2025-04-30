import 'package:flutter/material.dart';
import 'package:legalai/core/theme/app_theme.dart';

// Modern typing indicator
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({Key? key}) : super(key: key);

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
    return Align( // Align to left for AI typing
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 20, right: 120, left: 16), // Consistent margins
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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

  Widget _buildDot({required double delay}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double opacity = (((_controller.value + delay) % 1.0) < 0.5)
            ? ((_controller.value + delay) % 0.5) * 2
            : 1.0 - (((_controller.value + delay) % 0.5) * 2);
            
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.3 + (opacity * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
} 