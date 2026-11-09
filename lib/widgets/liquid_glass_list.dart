import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class IosGlassSection extends StatelessWidget {
  final String? header;
  final List<Widget> children;

  const IosGlassSection({
    super.key,
    this.header,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    final glassColor = isDark
        ? const Color(0xFF1C1C1E).withValues(alpha: 0.65)
        : CupertinoColors.white.withValues(alpha: 0.70);

    final borderColor = isDark
        ? CupertinoColors.white.withValues(alpha: 0.12)
        : CupertinoColors.white.withValues(alpha: 0.60);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 14.0, bottom: 6.0),
              child: Text(
                header!.toUpperCase(),
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(26.0), // iOS Inset Grouped Radius
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                decoration: BoxDecoration(
                  color: glassColor,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                child: Column(
                  children: List.generate(children.length, (index) {
                    return Column(
                      children: [
                        children[index],
                        if (index < children.length - 1)
                          Divider(
                            height: 0.8,
                            indent: 54,
                            endIndent: 0,
                            color: CupertinoColors.separator
                                .resolveFrom(context)
                                .withValues(alpha: 0.35),
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IosGlassTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const IosGlassTile({
    super.key,
    required this.icon,
    this.iconColor = const Color(0xFFE10600), // F1 Kırmızı
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 11.0),
      leading: Container(
        padding: const EdgeInsets.all(6.0),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(9.0),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.3,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle!,
        style: TextStyle(
          fontSize: 12.5,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(
            CupertinoIcons.chevron_forward,
            size: 16,
            color: CupertinoColors.tertiaryLabel,
          )
              : null),
      onTap: onTap,
    );
  }
}