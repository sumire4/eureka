import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<T?> showIosGlassDialog<T>({
  required BuildContext context,
  required String title,
  required String message,
  String cancelText = 'Vazgeç',
  String confirmText = 'Tamam',
  bool isDestructive = false,
  VoidCallback? onConfirm,
}) {
  return showCupertinoDialog<T>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final isDark = CupertinoTheme.brightnessOf(ctx) == Brightness.dark;
      final dialogBg = isDark
          ? const Color(0xFF1E1E22).withValues(alpha: 0.75)
          : const Color(0xFFF2F2F7).withValues(alpha: 0.85);

      return Center(
        child: Container(
          width: 275,
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: dialogBg,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                      child: Column(
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 0.6,
                      color: CupertinoColors.separator.resolveFrom(ctx).withValues(alpha: 0.35),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text(
                              cancelText,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: CupertinoColors.label.resolveFrom(ctx),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 0.6,
                          height: 44,
                          color: CupertinoColors.separator.resolveFrom(ctx).withValues(alpha: 0.35),
                        ),
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            onPressed: () {
                              Navigator.of(ctx).pop(true);
                              onConfirm?.call();
                            },
                            child: Text(
                              confirmText,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDestructive
                                    ? CupertinoColors.destructiveRed
                                    : const Color(0xFFE10600), // F1 Kırmızı
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}