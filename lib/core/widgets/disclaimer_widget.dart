import 'package:flutter/material.dart';

class DisclaimerWidget extends StatelessWidget {
  final String text;
  final EdgeInsets padding;
  final Color backgroundColor;
  final Color textColor;

  const DisclaimerWidget({
    Key? key,
    required this.text,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    this.backgroundColor = Colors.amberAccent, // Dikkat çekici bir renk
    this.textColor = Colors.black87,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Genişliği doldur
      color: backgroundColor,
      padding: padding,
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          // fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
} 