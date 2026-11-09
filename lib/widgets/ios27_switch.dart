import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class Ios27Switch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  const Ios27Switch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  // Figma iOS 27 Spesifikasyonları
  static const double _trackWidth = 64.0;
  static const double _trackHeight = 28.0;
  static const double _knobWidth = 38.0;
  static const double _knobHeight = 24.0;
  static const double _padding = 2.0;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    // Figma #34C759 veya Tema Rengi (Varsayılan Yeşil, F1 Kırmızı desteğiyle)
    final onColor = activeColor ?? const Color(0xFF34C759);
    final offColor = isDark
        ? const Color(0xFF39393D)
        : const Color(0xFFE9E9EB);

    return Semantics(
      toggled: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onChanged(!value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: _trackWidth,
          height: _trackHeight,
          padding: const EdgeInsets.all(_padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100.0), // Radius: 100px
            color: value ? onColor : offColor,
            border: Border.all(
              color: value
                  ? CupertinoColors.transparent
                  : (isDark
                  ? CupertinoColors.white.withValues(alpha: 0.12)
                  : CupertinoColors.black.withValues(alpha: 0.08)),
              width: 0.6,
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: _knobWidth,
              height: _knobHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100.0), // Oval hap knob
                color: CupertinoColors.white,
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.16),
                    blurRadius: 4.0,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.06),
                    blurRadius: 1.0,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}