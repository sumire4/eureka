import 'package:flutter/material.dart';

class HataEkrani extends StatelessWidget {
  final String mesaj;
  final VoidCallback? onTekrarDene;

  const HataEkrani({
    Key? key,
    this.mesaj = "Bir hata oluştu. Lütfen tekrar deneyin.",
    this.onTekrarDene,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/no_connection.png', // PNG dosyanızı buraya koyun
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text(
              mesaj,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (onTekrarDene != null)
              ElevatedButton.icon(
                onPressed: onTekrarDene,
                icon: const Icon(Icons.refresh),
                label: const Text("Tekrar Dene"),
              ),
          ],
        ),
      ),
    );
  }
}
