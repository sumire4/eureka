import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eureka/views/news/circuit_coordinates.dart';

class CircuitNavigationCard extends StatefulWidget {
  final String circuitName;
  final String countryName;
  final String meetingName;
  final double? lat;
  final double? lng;

  const CircuitNavigationCard({
    super.key,
    required this.circuitName,
    required this.countryName,
    required this.meetingName,   // yeni
    this.lat,
    this.lng,
  });

  @override
  State<CircuitNavigationCard> createState() => _CircuitNavigationCardState();
}

class _CircuitNavigationCardState extends State<CircuitNavigationCard> {
  static const _f1Red = Color(0xFFE10600);

  bool _loading = false;
  double? _distanceMeters;
  String? _error;
  bool _needsSettings = false;

  /// Pist koordinatı: modelden gelir, yoksa isimden geocode edilir.
  Future<({double lat, double lng})?> _resolveDestination() async {
    if (widget.lat != null && widget.lng != null) {
      return (lat: widget.lat!, lng: widget.lng!);
    }
    return CircuitCoordinates.find(widget.circuitName, widget.meetingName);
  }

  Future<void> _measureDistance() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      _needsSettings = false;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Konum servisleri kapalı. Ayarlardan açabilirsiniz.';
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw 'Konum izni verilmedi.';
      }
      if (permission == LocationPermission.deniedForever) {
        _needsSettings = true;
        throw 'Konum izni kapalı. Ayarlardan izin verebilirsiniz.';
      }

      final dest = await _resolveDestination();
      if (dest == null) throw 'Pist konumu bulunamadı.';

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final meters = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        dest.lat,
        dest.lng,
      );

      if (!mounted) return;
      setState(() => _distanceMeters = meters);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is String ? e : 'Konum alınamadı, tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openMaps() async {
    final dest = await _resolveDestination();
    if (!mounted) return;
    if (dest == null) {
      setState(() => _error = 'Pist konumu bulunamadı.');
      return;
    }

    final apple = Uri.https('maps.apple.com', '/', {
      'daddr': '${dest.lat},${dest.lng}',
      'q': widget.circuitName,
      'dirflg': 'd',
    });
    final google = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${dest.lat},${dest.lng}',
    });

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(widget.circuitName),
        message: const Text('Yol tarifi için bir harita uygulaması seçin'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              launchUrl(apple, mode: LaunchMode.externalApplication);
            },
            child: const Text('Apple Haritalar'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              launchUrl(google, mode: LaunchMode.externalApplication);
            },
            child: const Text('Google Maps'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Vazgeç'),
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    final km = (meters / 1000).round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < km.length; i++) {
      if (i > 0 && (km.length - i) % 3 == 0) buf.write('.');
      buf.write(km[i]);
    }
    return '$buf km';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CupertinoColors.systemGrey5.resolveFrom(context),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.location_solid, size: 16, color: _f1Red),
              SizedBox(width: 6),
              Text(
                'PİSTE ULAŞIM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.secondaryLabel,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Uzaklık sonucu alanı
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildDistanceArea(context),
          ),

          const SizedBox(height: 14),

          // Uzaklığı ölç
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 13),
              color: CupertinoColors.systemGrey5.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
              onPressed: _loading ? null : _measureDistance,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_loading)
                    const CupertinoActivityIndicator()
                  else
                    const Icon(CupertinoIcons.scope, size: 18, color: _f1Red),
                  const SizedBox(width: 8),
                  Text(
                    _distanceMeters == null ? 'Uzaklığımı Ölç' : 'Yeniden Ölç',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Haritalarda aç
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 13),
              color: _f1Red,
              borderRadius: BorderRadius.circular(12),
              onPressed: _openMaps,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.location_north_fill,
                      size: 17, color: CupertinoColors.white),
                  SizedBox(width: 8),
                  Text(
                    'Haritalarda Yol Tarifi Al',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceArea(BuildContext context) {
    if (_error != null) {
      return Row(
        key: const ValueKey('error'),
        children: [
          const Icon(CupertinoIcons.exclamationmark_circle_fill,
              size: 18, color: CupertinoColors.systemOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                  fontSize: 13, color: CupertinoColors.secondaryLabel),
            ),
          ),
          if (_needsSettings)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: Geolocator.openAppSettings, minimumSize: Size(0, 0),
              child: const Text('Ayarlar', style: TextStyle(fontSize: 13)),
            ),
        ],
      );
    }

    if (_distanceMeters != null) {
      return Row(
        key: const ValueKey('result'),
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatDistance(_distanceMeters!),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(width: 8),
          const Padding(
            padding: EdgeInsets.only(bottom: 5),
            child: Text(
              'kuş uçuşu',
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ),
        ],
      );
    }

    return const Text(
      'Bulunduğun konumdan piste olan mesafeyi görmek için ölç butonuna dokun.',
      key: ValueKey('idle'),
      style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel),
    );
  }
}