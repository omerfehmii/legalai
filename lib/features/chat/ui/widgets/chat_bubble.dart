import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Zaman formatı için

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUserMessage;
  final DateTime timestamp;
  final String? disclaimer; // AI mesajları için ek uyarı

  const ChatBubble({
    Key? key,
    required this.text,
    required this.isUserMessage,
    required this.timestamp,
    this.disclaimer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isUserMessage ? theme.colorScheme.primary : theme.colorScheme.secondaryContainer;
    final textColor = isUserMessage ? theme.colorScheme.onPrimary : theme.colorScheme.onSecondaryContainer;
    final bubbleAlignment = isUserMessage ? Alignment.centerRight : Alignment.centerLeft;
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
      bottomLeft: isUserMessage ? Radius.circular(12) : Radius.circular(0),
      bottomRight: isUserMessage ? Radius.circular(0) : Radius.circular(12),
    );

    // Zaman formatı
    // final timeFormat = DateFormat('HH:mm'); // Sadece saat:dakika
    // final formattedTime = timeFormat.format(timestamp);

    return Container(
      alignment: bubbleAlignment,
      margin: EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75), // Maks genişlik
        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
        ),
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start, // Metni sola yasla
           mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(color: textColor),
            ),
            // if (disclaimer != null) ...[
            //   SizedBox(height: 4),
            //   Text(
            //     disclaimer!,
            //     style: TextStyle(
            //       color: textColor.withOpacity(0.8),
            //       fontSize: 10,
            //       fontStyle: FontStyle.italic,
            //     ),
            //   )
            // ],
            // SizedBox(height: 2),
            // Text( // Zaman damgası (opsiyonel)
            //   formattedTime,
            //   style: TextStyle(
            //     color: textColor.withOpacity(0.7),
            //     fontSize: 10,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
} 