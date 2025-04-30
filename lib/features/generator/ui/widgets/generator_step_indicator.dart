import 'package:flutter/material.dart';
import 'package:legalai/core/theme/app_theme.dart';

class GeneratorStepIndicator extends StatelessWidget {
  final int currentStep; // 0-indexed
  final List<String> steps;

  const GeneratorStepIndicator({
    super.key,
    required this.currentStep,
    required this.steps,
  }) : assert(steps.length > 0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      color: AppTheme.backgroundColor.withOpacity(0.5), // Semi-transparent background
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(steps.length, (index) {
          final bool isActive = index == currentStep;
          final bool isCompleted = index < currentStep;
          final Color indicatorColor = isCompleted || isActive ? AppTheme.primaryColor : Colors.grey[300]!;
          final Color textColor = isCompleted || isActive ? AppTheme.primaryColor : Colors.grey[500]!;

          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Step indicator circle
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? indicatorColor : Colors.transparent,
                    border: Border.all(
                      color: indicatorColor,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: AppTheme.primaryColor)
                        : isActive
                            ? Container( // Small inner dot for active step
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              )
                            : null, // Empty circle for future steps
                  ),
                ),
                const SizedBox(height: 4),
                // Step label
                Text(
                  steps[index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
} 