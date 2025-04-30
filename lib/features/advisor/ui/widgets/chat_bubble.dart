import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Zaman formatı için
import 'package:legalai/core/theme/app_theme.dart';

// Modern Chat Bubble Widget
class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUserMessage;
  final String timestamp;
  final bool highlight;

  const ChatBubble({
    Key? key, // Add key
    required this.text,
    required this.isUserMessage,
    required this.timestamp,
    this.highlight = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isUserMessage 
        ? theme.colorScheme.primary 
        : (highlight ? theme.colorScheme.secondaryContainer : Colors.grey[200]);
    final textColor = isUserMessage 
        ? theme.colorScheme.onPrimary 
        : (highlight ? theme.colorScheme.onSecondaryContainer : Colors.black87);

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isUserMessage ? 20 : 4),
              bottomRight: Radius.circular(isUserMessage ? 4 : 20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            top: 6,
            left: isUserMessage ? 0 : 8,
            right: isUserMessage ? 8 : 0,
          ),
          child: Text(
            timestamp,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ),
      ],
    );
  }
} 