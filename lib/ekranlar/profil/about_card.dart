import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../EasterEggScreen.dart';

class AboutCard extends StatefulWidget {
  final String version;

  const AboutCard({super.key, required this.version});

  @override
  State<AboutCard> createState() => _AboutCardState();
}

class _AboutCardState extends State<AboutCard> {
  int _tapCount = 0;
  DateTime? _firstTapTime;

  void _handleTap() {
    final now = DateTime.now();
    if (_firstTapTime == null || now.difference(_firstTapTime!) > const Duration(seconds: 3)) {
      _firstTapTime = now;
      _tapCount = 1;
    } else {
      _tapCount++;
      if (_tapCount >= 5) {
        _tapCount = 0;
        _firstTapTime = null;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EasterEggScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              color: theme.colorScheme.primary,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Project Eureka',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Türk F1 tutkunları için bir arada tüm bilgileri sunan, kullanımı kolay Android uygulaması.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              '© 2025 Tüm hakları saklıdır.',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Versiyon: ${widget.version}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
