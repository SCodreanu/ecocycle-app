import 'package:flutter/material.dart';

import '../../models/recycling_point.dart';
import '../../services/recycling_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _recyclingService = RecyclingService();

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

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: points.length,
                itemBuilder: (context, index) {
                  final point = points[index];

                  final typeLabel =
                      switch (point.recyclingType) {
                    'centre' => 'Centro di riciclo',
                    'container' =>
                      'Contenitore per il riciclo',
                    _ => 'Punto di riciclo',
                  };

                  return ListTile(
                    leading:
                        const Icon(Icons.recycling),
                    title: Text(
                      point.name ?? typeLabel,
                    ),
                    subtitle: Text(
                      '${point.latitude.toStringAsFixed(5)}, '
                      '${point.longitude.toStringAsFixed(5)}',
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: SelectableText(
                'Dati © OpenStreetMap · openstreetmap.org/copyright',
                style:
                    Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }
}