import 'package:flutter/material.dart';

// Logo "SAPA PPKD" yang dipake di Dashboard dan Profile
class AppLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;

  const AppLogo({
    super.key,
    this.iconSize = 22,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.grid_view, size: iconSize, color: const Color(0xFF003F87)),
        const SizedBox(width: 8),
        Text(
          "SAPA PPKD",
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF003F87),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
