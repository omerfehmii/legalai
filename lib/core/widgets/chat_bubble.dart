import 'package:flutter/material.dart';
import 'package:legalai/core/theme/app_theme.dart'; // Import AppTheme

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUserMessage;
  final String timestamp;
  final Widget? leading; // AI avatar

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
    final bubbleAlignment = isUserMessage ? Alignment.centerRight : Alignment.centerLeft;
    
    // --- New Colors --> Flat & Lighter --- 
    final bubbleColor = isUserMessage ? AppTheme.secondaryColor : Colors.white;
    final textColor = isUserMessage ? Colors.white : AppTheme.textColor;
    
    // --- Margins for Spacing --- 
    // Increased vertical margin
    final margin = EdgeInsets.only(
      left: isUserMessage ? 60 : 16, // Indent user more, AI less (adjust as needed)
      right: isUserMessage ? 16 : 60, // Indent AI more, user less
      top: 8, 
      bottom: 8, // Increased vertical spacing
    );
    
    // --- Symmetrical Rounded Corners --- 
    final bubbleBorderRadius = BorderRadius.circular(16); // Consistent rounding

    // --- Bubble Content --- 
    Widget bubbleContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: bubbleBorderRadius,
        // --- REMOVE SHADOW for Flat Design ---
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.04),
        //     blurRadius: 8,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyLarge?.copyWith(
              color: textColor, // Apply new text color
              // Ensure font family from theme is used if needed
              // fontFamily: theme.textTheme.bodyLarge?.fontFamily, 
              height: 1.45, // Slightly increased line height for readability
            ) ?? TextStyle( // Fallback style
              color: textColor,
              fontSize: 15,
              height: 1.45,
            ),
      ),
    );

    // --- Row for Avatar + Bubble (AI only) ---
    Widget messageRow = Row(
      mainAxisSize: MainAxisSize.min, 
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        if (!isUserMessage && leading != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 2), // Align avatar slightly better
            child: leading!,
          ),
          const SizedBox(width: 10), // Space between avatar and bubble
        ],
        Flexible(child: bubbleContent), // Bubble takes remaining space
      ],
    );
    
    // --- Final Layout with Timestamp --- 
    return Container(
      margin: margin,
      alignment: bubbleAlignment,
      child: Column(
        crossAxisAlignment: alignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Use messageRow for AI, just bubbleContent for user
          isUserMessage ? bubbleContent : messageRow,
          Padding(
            padding: EdgeInsets.only(
              top: 6, // Space above timestamp
              left: isUserMessage ? 0 : (leading != null ? 58 : 0), // Align under bubble/avatar
              right: isUserMessage ? 4 : 0,
            ),
            child: Text(
              timestamp,
              style: theme.textTheme.bodySmall?.copyWith(
                 color: AppTheme.mutedTextColor.withOpacity(0.8), // Make timestamp slightly fainter
              ) ?? TextStyle(
                 fontSize: 11, // Fallback size
                 color: AppTheme.mutedTextColor.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 