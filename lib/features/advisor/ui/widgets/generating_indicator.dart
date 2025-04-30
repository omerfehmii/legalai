import 'package:flutter/material.dart';

// Placeholder for Generating Indicator
class GeneratingIndicator extends StatelessWidget {
  const GeneratingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16, 
              height: 16, 
              child: CircularProgressIndicator(strokeWidth: 2)
            ),
            SizedBox(width: 10),
            Text(
              'Belge oluşturuluyor...', 
              style: TextStyle(
                fontSize: 14, 
                color: Theme.of(context).colorScheme.onPrimaryContainer
              )
            ),
          ],
        ),
      ),
    );
  }
} 