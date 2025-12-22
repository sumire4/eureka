import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TesekkurCard extends StatelessWidget {
  const TesekkurCard({super.key});

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('URL açılamadı: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: double.infinity,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wine_bar, color: theme.colorScheme.primary, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'Teşekkürler',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogoButton(
                    assetPath: 'assets/logos/f1tr.png',
                    url: 'https://www.f1tr.com/',
                  ),
                  const SizedBox(width: 16), // butonlar arası boşluk
                  _buildLogoButton(
                    assetPath: 'assets/logos/motorsport.png',
                    url: 'https://tr.motorsport.com/',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoButton({required String assetPath, required String url}) {
    return SizedBox(
      width: 130, // daha küçük genişlik
      height: 45, // daha küçük yükseklik
      child: FilledButton(
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () => _launchURL(url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            height: 45,
          ),
        ),
      ),
    );
  }
}
