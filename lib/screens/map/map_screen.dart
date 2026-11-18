import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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

  @override
  void initState() {
    super.initState();

    _points = _recyclingService.fetchRecyclingPoints();
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

        return FlutterMap(
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
              ],
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