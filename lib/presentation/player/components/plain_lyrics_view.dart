import 'package:flutter/material.dart';

class PlainLyricsView extends StatelessWidget {
  final String text;
  final Color accentColor;

  const PlainLyricsView({super.key, required this.text, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.6, fontWeight: FontWeight.w500),
      ),
    );
  }
}
