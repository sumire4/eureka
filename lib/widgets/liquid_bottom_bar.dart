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
  final bool isCompact; // Aşağı kaydırınca küçülme bayrağı

  static const Color accentRed = Color(0xFFE10600);

  // Standart ve Kompakt Ölçüler
  static const double _barHeightNormal = 62.0;
  static const double _barHeightCompact = 52.0;
  static const double _pillHeightNormal = 54.0;
  static const double _pillHeightCompact = 44.0;
  static const double _iconSize = 22.0;
  static const double _fontSize = 10.0;

  const LiquidPillBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.isCompact = false,
  });

  @override
  State<LiquidPillBottomBar> createState() => _LiquidPillBottomBarState();
}

class _LiquidPillBottomBarState extends State<LiquidPillBottomBar> {
  int? _hoveredIndex;

  void _updateIndexFromPosition(Offset localPosition, double itemWidth) {
    const double horizontalMargin = 4.0;
    final double dx = localPosition.dx - horizontalMargin;

    if (dx >= 0 && itemWidth > 0) {
      final int newIndex = (dx / itemWidth)
          .floor()
          .clamp(0, widget.items.length - 1);

      if (newIndex != _hoveredIndex) {
        setState(() => _hoveredIndex = newIndex);
        HapticFeedback.selectionClick();
        widget.onTap(newIndex);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final activeIndex = _hoveredIndex ?? widget.currentIndex;

    final currentBarHeight = widget.isCompact
        ? LiquidPillBottomBar._barHeightCompact
        : LiquidPillBottomBar._barHeightNormal;

    final currentPillHeight = widget.isCompact
        ? LiquidPillBottomBar._pillHeightCompact
        : LiquidPillBottomBar._pillHeightNormal;

    final double barRadius = currentBarHeight / 2;
    final double pillRadius = currentPillHeight / 2;

    // Figma iOS 27 Renk ve Gölgeleri
    final glassTopColor = isDark
        ? const Color(0xFF282828).withValues(alpha: 0.70)
        : const Color(0xFFE6E6E6).withValues(alpha: 0.88);

    final glassBottomColor = isDark
        ? const Color(0xFF141416).withValues(alpha: 0.85)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.75);

    final borderRimColor = isDark
        ? CupertinoColors.white.withValues(alpha: 0.18)
        : CupertinoColors.white.withValues(alpha: 0.70);

    final activePillColor = isDark
        ? CupertinoColors.white.withValues(alpha: 0.15)
        : CupertinoColors.black.withValues(alpha: 0.07);

    final inactiveLabelColor = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF3C3C43).withValues(alpha: 0.80);

    final shadowColor = isDark
        ? CupertinoColors.black.withValues(alpha: 0.45)
        : CupertinoColors.black.withValues(alpha: 0.12);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: bottomPadding > 0 ? 4 : 12,
        ),
        child: Center(
          // Kaydırırken hafif küçülme animasyonu (Scale 0.94x)
          child: AnimatedScale(
            scale: widget.isCompact ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              // Yüksekliğin animasyonla daralması
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                height: currentBarHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(barRadius),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: widget.isCompact ? 16 : 28,
                        spreadRadius: -4,
                        offset: Offset(0, widget.isCompact ? 6 : 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(barRadius),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(barRadius),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [glassTopColor, glassBottomColor],
                          ),
                          border: Border.all(
                            color: borderRimColor,
                            width: 0.8,
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            const double horizontalMargin = 4.0;
                            final double availableWidth = constraints.maxWidth - (horizontalMargin * 2);
                            final double dynamicItemWidth = availableWidth / widget.items.length;

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (d) => _updateIndexFromPosition(d.localPosition, dynamicItemWidth),
                              onPanUpdate: (d) => _updateIndexFromPosition(d.localPosition, dynamicItemWidth),
                              onPanEnd: (_) => setState(() => _hoveredIndex = null),
                              onPanCancel: () => setState(() => _hoveredIndex = null),
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  // 1. Kayan Aktif Hap (Yüksekliği de barla orantılı küçülür)
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 240),
                                    curve: Curves.easeOutCubic,
                                    left: horizontalMargin + (activeIndex * dynamicItemWidth),
                                    top: (currentBarHeight - currentPillHeight) / 2,
                                    width: dynamicItemWidth,
                                    height: currentPillHeight,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      curve: Curves.easeOutCubic,
                                      decoration: BoxDecoration(
                                        color: activePillColor,
                                        borderRadius: BorderRadius.circular(pillRadius),
                                      ),
                                    ),
                                  ),

                                  // 2. İkonlar ve Metinler
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: horizontalMargin),
                                    child: Row(
                                      children: List.generate(widget.items.length, (index) {
                                        final isSelected = index == activeIndex;
                                        final isDragging = _hoveredIndex != null && isSelected;
                                        final item = widget.items[index];
                                        final color = isSelected
                                            ? LiquidPillBottomBar.accentRed
                                            : inactiveLabelColor;

                                        return Expanded(
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () {
                                              HapticFeedback.lightImpact();
                                              widget.onTap(index);
                                            },
                                            child: SizedBox(
                                              height: currentBarHeight,
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  AnimatedScale(
                                                    scale: isDragging ? 1.15 : (isSelected ? 1.05 : 1.0),
                                                    duration: const Duration(milliseconds: 180),
                                                    curve: Curves.easeOutCubic,
                                                    child: Icon(
                                                      isSelected ? item.activeIcon : item.icon,
                                                      size: LiquidPillBottomBar._iconSize,
                                                      color: color,
                                                    ),
                                                  ),
                                                  // Kaydırma esnasında etiket hafifçe gizlenir, sadece şık ikon kalır
                                                  AnimatedCrossFade(
                                                    duration: const Duration(milliseconds: 180),
                                                    crossFadeState: widget.isCompact
                                                        ? CrossFadeState.showSecond
                                                        : CrossFadeState.showFirst,
                                                    firstChild: Padding(
                                                      padding: const EdgeInsets.only(top: 2.5),
                                                      child: Text(
                                                        item.label,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontFamily: 'SF Pro',
                                                          fontSize: LiquidPillBottomBar._fontSize,
                                                          fontWeight: isSelected
                                                              ? FontWeight.w600
                                                              : FontWeight.w500,
                                                          color: color,
                                                          decoration: TextDecoration.none,
                                                        ),
                                                      ),
                                                    ),
                                                    secondChild: const SizedBox.shrink(),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
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