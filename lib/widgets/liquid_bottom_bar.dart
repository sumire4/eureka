import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class LiquidBottomBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const LiquidBottomBarItem({
    required this.icon,
    required this.activeIcon,
    this.label = '',
  });
}

class LiquidPillBottomBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LiquidBottomBarItem> items;

  static const Color accentRed = Color(0xFFE10600);

  static const double _height = 68;
  static const double _itemWidth = 88;
  static const double _iconSize = 26;
  static const double _labelSize = 11;

  const LiquidPillBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<LiquidPillBottomBar> createState() => _LiquidPillBottomBarState();
}

class _LiquidPillBottomBarState extends State<LiquidPillBottomBar> {
  // Parmağın basılı tutulup gezdirildiği anlık sekme indeksi
  int? _hoveredIndex;

  void _updateIndexFromPosition(Offset localPosition) {
    // Toplam genişlik ve x eksenindeki ofset hesaplaması
    final double totalWidth = widget.items.length * LiquidPillBottomBar._itemWidth;
    final double dx = localPosition.dx - 8; // 8px horizontal padding dengesi

    if (dx >= 0 && dx < totalWidth) {
      final int newIndex = (dx / LiquidPillBottomBar._itemWidth)
          .floor()
          .clamp(0, widget.items.length - 1);

      if (newIndex != _hoveredIndex) {
        setState(() {
          _hoveredIndex = newIndex;
        });
        // İkonlar arası gezerken iOS dokunsal geri bildirimi
        HapticFeedback.selectionClick();
        widget.onTap(newIndex);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasHomeIndicator = MediaQuery.of(context).padding.bottom > 0;
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final activeIndex = _hoveredIndex ?? widget.currentIndex;

    // Seçili butonun arka plan vurgusu
    final selectedBgColor = isDark
        ? CupertinoColors.white.withValues(alpha: 0.14)
        : CupertinoColors.black.withValues(alpha: 0.08);

    // Arkadaki görsel ve renklerin okunurluğu bozmaması için artırılmış cam opaklığı
    final glassTop = isDark ? const Color(0x992C2C2E) : const Color(0xF2FFFFFF);
    final glassBottom = isDark ? const Color(0x801C1C1E) : const Color(0xD9FFFFFF);
    final glassTint = isDark ? const Color(0xCC121214) : const Color(0xCCFFFFFF);

    // Açık temada okunurluğu korumak için kontrastı artırılmış pasif renk
    final inactiveColor = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF3C3C43).withValues(alpha: 0.85);

    final shadowColor = isDark
        ? CupertinoColors.black.withValues(alpha: 0.45)
        : CupertinoColors.black.withValues(alpha: 0.14);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: hasHomeIndicator ? 4 : 12),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LiquidPillBottomBar._height / 2),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 28,
                  spreadRadius: -2,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(LiquidPillBottomBar._height / 2),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) => _updateIndexFromPosition(details.localPosition),
                  onPanUpdate: (details) => _updateIndexFromPosition(details.localPosition),
                  onPanEnd: (_) => setState(() => _hoveredIndex = null),
                  onPanCancel: () => setState(() => _hoveredIndex = null),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: LiquidPillBottomBar._height,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: glassTint,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          glassTop,
                          glassBottom,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(LiquidPillBottomBar._height / 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(widget.items.length, (index) {
                        final isSelected = index == activeIndex;
                        final isDragging = _hoveredIndex != null && isSelected;
                        final item = widget.items[index];
                        final color = isSelected ? LiquidPillBottomBar.accentRed : inactiveColor;

                        return Semantics(
                          button: true,
                          selected: isSelected,
                          label: item.label.isEmpty ? null : item.label,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              widget.onTap(index);
                            },
                            child: SizedBox(
                              width: LiquidPillBottomBar._itemWidth,
                              height: LiquidPillBottomBar._height,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  decoration: BoxDecoration(
                                    color: isSelected ? selectedBgColor : const Color(0x00000000),
                                    borderRadius: BorderRadius.circular(
                                        (LiquidPillBottomBar._height - 12) / 2),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedScale(
                                        scale: isDragging ? 1.20 : (isSelected ? 1.08 : 1.0),
                                        duration: const Duration(milliseconds: 180),
                                        curve: Curves.easeOutCubic,
                                        child: Icon(
                                          isSelected ? item.activeIcon : item.icon,
                                          size: LiquidPillBottomBar._iconSize,
                                          color: color,
                                        ),
                                      ),
                                      if (item.label.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        AnimatedDefaultTextStyle(
                                          duration: const Duration(milliseconds: 180),
                                          style: TextStyle(
                                            fontSize: LiquidPillBottomBar._labelSize,
                                            height: 1.1,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                            color: color,
                                            decoration: TextDecoration.none,
                                          ),
                                          child: Text(
                                            item.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}