import 'package:flutter/cupertino.dart';

class LiquidBackground extends StatelessWidget {
  final Widget child;

  const LiquidBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Zemin ana rengi
        Container(
          color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
        ),

        // Sol üstteki sıcak yansıma (F1 kırmızısı ambient ışık)
        Positioned(
          top: -80,
          left: -40,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFE10600).withValues(alpha: 0.12),
                  const Color(0xFFE10600).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // Sağ alttaki yumuşak güneş/amber yansıması
        Positioned(
          top: 180,
          right: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFF9500).withValues(alpha: 0.10),
                  const Color(0xFFFF9500).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // Ana içerik
        Positioned.fill(child: child),
      ],
    );
  }
}