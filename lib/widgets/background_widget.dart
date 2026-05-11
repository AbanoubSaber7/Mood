import 'package:flutter/material.dart';

class BackgroundTheme {
  final Color bgColor;
  final Color blobColor;
  final Color textColor; // added variable for text color

  BackgroundTheme(this.bgColor, this.blobColor, this.textColor);
}

class BackgroundWidget extends StatelessWidget {
  final Widget child;
  final String emotion;

  const BackgroundWidget({
    Key? key,
    required this.child,
    this.emotion = 'happy',
  }) : super(key: key);

  BackgroundTheme _getTheme() {
    switch (emotion.toLowerCase()) {
      case 'sad':
        // Very dark background, grey blobs, white text
        return BackgroundTheme(Colors.black, Colors.white10, Colors.white);
      case 'neutral':
        return BackgroundTheme(
          const Color(0xFFF5F5F5),
          const Color(0xFFBDC3C7),
          Colors.black87,
        );
      case 'angry':
        // Very dark red background, white text for contrast
        return BackgroundTheme(
          const Color(0xFF4E1D1D),
          const Color(0xFFC0392B),
          Colors.white,
        );
      case 'fear':
        return BackgroundTheme(
          const Color(0xFF1A1A2E),
          const Color(0xFF16213E),
          Colors.white,
        );
      case 'disgust':
        return BackgroundTheme(
          const Color(0xFF1E2611),
          const Color(0xFF3B4D28),
          Colors.white,
        );
      case 'surprise':
        return BackgroundTheme(
          const Color(0xFFFFF9E3),
          const Color(0xFFF1C40F),
          Colors.black87,
        );
      case 'happy':
      default:
        return BackgroundTheme(
          const Color(0xFFFFF5F5),
          const Color(0xFFFADBD8),
          Colors.black87,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getTheme();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      color: theme.bgColor,
      child: Stack(
        children: [
          // Blobs
          _buildBlob(
            top: -70,
            left: -40,
            size: 200,
            color: theme.blobColor,
            opacity: 0.3,
          ),
          _buildBlob(
            bottom: -100,
            left: -50,
            size: 300,
            color: theme.blobColor,
            opacity: 0.2,
          ),

          // Use DefaultTextStyle so any text inside `child`
          // inherits the appropriate color for the current background
          DefaultTextStyle(
            style: TextStyle(color: theme.textColor),
            child: Theme(
              // ده بيغير لون الـ Icons كمان عشان تظهر على الخلفية الغامقة
              data: Theme.of(context).copyWith(
                // Also update icon theme so icons are visible on dark backgrounds
                iconTheme: IconThemeData(color: theme.textColor),
              ),
              child: SafeArea(child: child),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
    required double opacity,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
