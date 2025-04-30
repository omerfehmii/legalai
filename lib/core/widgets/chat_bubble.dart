import 'package:flutter/material.dart';
import 'package:legalai/core/theme/app_theme.dart'; // Assuming AppTheme provides necessary colors

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUserMessage;
  final String timestamp;
  final Widget? leading; // Optional leading widget (e.g., for AI avatar)

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUserMessage,
    required this.timestamp,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    // Slightly different colors/styles for user vs AI
    final bubbleColor = isUserMessage ? AppTheme.primaryColor : Colors.grey[100]; // Lighter grey for AI
    final textColor = isUserMessage ? Colors.white : Colors.black87; // White text on primary, dark on grey
    final bubbleAlignment = isUserMessage ? Alignment.centerRight : Alignment.centerLeft;
    final margin = isUserMessage
        ? const EdgeInsets.only(left: 50, top: 5, bottom: 5, right: 10) // Indent user messages more from left
        : const EdgeInsets.only(right: 50, top: 5, bottom: 5, left: 10); // Indent AI messages more from right
    final bubbleBorderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isUserMessage ? 18 : 4),
      bottomRight: Radius.circular(isUserMessage ? 4 : 18),
    );

    // Main content container (the bubble itself)
    Widget bubbleContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), // Adjusted padding
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: bubbleBorderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: Text(
        text,
        // Use theme's bodyLarge style and override color
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: textColor,
              height: 1.4, // Keep custom height if needed, or remove to use theme's default
            ) ?? TextStyle( // Fallback if bodyLarge is somehow null
              color: textColor,
              fontSize: 15.5,
              height: 1.35,
            ),
      ),
    );

    // Arrange leading widget (avatar) and bubble content
    Widget messageRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Take only needed space
      children: [
        if (leading != null && !isUserMessage) ...[
          leading!,
          const SizedBox(width: 8), // Space between avatar and bubble
        ],
        // Use Flexible for the bubble itself to allow wrapping
        Flexible(child: bubbleContent),
      ],
    );

    return Container(
      margin: margin,
      alignment: bubbleAlignment,
      child: Column(
        crossAxisAlignment: alignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          messageRow, // Use the Row containing avatar + bubble
          Padding(
            padding: EdgeInsets.only(
              top: 5,
              left: isUserMessage ? 0 : (leading != null ? 48 : 8), // Align timestamp under bubble
              right: isUserMessage ? 8 : 0,
            ),
            child: Text(
              timestamp,
              // Use theme's bodySmall style for timestamp (caption is assigned to bodySmall in our theme)
              style: Theme.of(context).textTheme.bodySmall ?? TextStyle(
                 fontSize: 10.5,
                 color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 