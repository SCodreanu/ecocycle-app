import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../models/recycling_point.dart';
import '../../services/recycling_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _recyclingService = RecyclingService();
  final _mapController = MapController();

  late final _tileLayer = TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    tileProvider: NetworkTileProvider(
      headers: {
        if (bool.fromEnvironment('dart.library.io'))
          'User-Agent':
              'EcoCycle/1.0 (+https://github.com/SCodreanu/ecocycle-app)',
      },
    ),
  );

  late Future<List<RecyclingPoint>> _points;
  LatLng? _userLocation;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();

    _points = _recyclingService.fetchRecyclingPoints();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _centerOnUser() async {
    if (_isLocating) return;

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    setState(() {
      _isLocating = true;
      _userLocation = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        _showLocationServiceDisabled();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (!mounted) return;
      // Android also reports denied before the first permission request.
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationMessage(
          'Consenti l’accesso alla posizione nelle impostazioni dell’app.',
          openSettings: Geolocator.openAppSettings,
        );
        return;
      }
      if (permission == LocationPermission.denied) {
        _showLocationMessage(
          'Permesso di posizione negato. Tocca il pulsante per riprovare.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );
      if (!mounted) return;

      final location = LatLng(position.latitude, position.longitude);
      _mapController.move(location, _mapController.camera.zoom);
      setState(() {
        _userLocation = location;
      });
    } on LocationServiceDisabledException {
      if (mounted) _showLocationServiceDisabled();
    } catch (_) {
      if (mounted) {
        _showLocationMessage('Impossibile ottenere la posizione. Riprova.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  void _showLocationServiceDisabled() {
    _showLocationMessage(
      'La localizzazione è disattivata. Attivala nelle impostazioni.',
      openSettings: Geolocator.openLocationSettings,
    );
  }

  void _showLocationMessage(
    String message, {
    Future<bool> Function()? openSettings,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: openSettings == null
              ? null
              : SnackBarAction(
                  label: 'Impostazioni',
                  onPressed: () async {
                    try {
                      if (await openSettings()) return;
                    } catch (_) {
                      // Show the same message if Android cannot open settings.
                    }
                    if (mounted) {
                      _showLocationMessage(
                        'Impossibile aprire le impostazioni di Android.',
                      );
                    }
                  },
                ),
        ),
      );
  }

  void _retry() {
    setState(() {
      _points = _recyclingService.fetchRecyclingPoints();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RecyclingPoint>>(
      future: _points,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              semanticsLabel:
                  'Caricamento dei punti di riciclo',
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Impossibile caricare i punti di riciclo.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _retry,
                    child: const Text('Riprova'),
                  ),
                ],
              ),
            ),
          );
        }

        final points =
            snapshot.data ?? const <RecyclingPoint>[];

        if (points.isEmpty) {
          return const Center(
            child: Text(
              'Nessun punto di riciclo trovato nella zona di Torino.',
            ),
          );
        }

        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        final userLocation = _userLocation;

        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(45.07, 7.675),
            initialZoom: 12,
            maxZoom: 19,
            backgroundColor: colors.surface,
          ),
          children: [
            _tileLayer,
            MarkerLayer(
              markers: [
                for (final point in points)
                  Marker(
                    point: LatLng(point.latitude, point.longitude),
                    width: 28,
                    height: 28,
                    child: Tooltip(
                      message: point.name ?? 'Punto di riciclo',
                      child: CircleAvatar(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        child: const Icon(Icons.recycling, size: 18),
                      ),
                    ),
                  ),
                if (userLocation != null)
                  Marker(
                    point: userLocation,
                    width: 36,
                    height: 36,
                    child: Tooltip(
                      message: 'La tua posizione',
                      child: CircleAvatar(
                        backgroundColor: colors.tertiaryContainer,
                        foregroundColor: colors.onTertiaryContainer,
                        child: const Icon(Icons.my_location, size: 20),
                      ),
                    ),
                  ),
              ],
            ),
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
              Positioned(
                top: 12,
                right: 12,
                child: IconButton.filledTonal(
                  onPressed: _isLocating ? null : _centerOnUser,
                  tooltip: 'Centra sulla mia posizione',
                  icon: _isLocating
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            semanticsLabel: 'Ricerca della posizione',
                          ),
                        )
                      : const Icon(Icons.my_location),
                ),
              ),
            Align(
              alignment: Alignment.bottomRight,
              child: ColoredBox(
                color: colors.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: SelectableText(
                    '© OpenStreetMap contributors · ODbL\n'
                    'https://www.openstreetmap.org/copyright',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
