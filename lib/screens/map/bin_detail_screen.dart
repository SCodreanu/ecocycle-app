import 'package:flutter/material.dart';

import '../../models/bin_status.dart';
import '../../models/recycling_point.dart';

class BinDetailScreen extends StatelessWidget {
  const BinDetailScreen({
    super.key,
    required this.point,
    required this.onReport,
  });
  final RecyclingPoint point;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final demo = BinStatusData.forPoint(point);
    return Scaffold(
      appBar: AppBar(title: const Text('Dettaglio punto')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(point.title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'OpenStreetMap · ${point.key}',
            style: theme.textTheme.bodyMedium,
          ),
          if (point.address != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.place_outlined),
              title: Text(point.address!),
            ),
          Text(
            '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
          ),
          if (point.tags['operator'] case final operator?)
            Text('Gestore: $operator'),
          const SizedBox(height: 24),
          Text('Materiali conferibili', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          if (point.materials.isEmpty)
            const Text(
              'Informazioni non disponibili in OpenStreetMap. Verifica la segnaletica sul posto.',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: point.materials
                  .map((material) => Chip(label: Text(material)))
                  .toList(),
            ),
          if (point.isContainer) ...[
            const SizedBox(height: 28),
            Text('Stato del cassonetto', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text('Dati dimostrativi · non rilevati da sensori reali.'),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(demo.status.icon, color: demo.status.color),
                const SizedBox(width: 8),
                Expanded(child: Text(demo.status.label)),
                Text(
                  '${demo.fillLevel}%',
                  style: theme.textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: demo.fillLevel / 100,
              color: demo.status.color,
              minHeight: 9,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.thermostat),
              title: const Text('Temperatura'),
              trailing: Text('${demo.temperature.toStringAsFixed(1)} °C'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Capacità'),
              trailing: Text('${demo.capacity} L'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.scale_outlined),
              title: const Text('Peso'),
              trailing: Text('${demo.weight.toStringAsFixed(1)} kg'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.air),
              title: const Text('Lettura gas simulata'),
              trailing: Text('${demo.gasReading.toStringAsFixed(1)} ppm'),
            ),
            if (demo.status == BinStatus.full ||
                demo.status == BinStatus.maintenance ||
                demo.status == BinStatus.unavailable)
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.info_outline),
                title: Text('Avviso dimostrativo'),
                subtitle: Text(
                  'Non rappresenta una condizione verificata sul posto.',
                ),
              ),
          ] else ...[
            const SizedBox(height: 20),
            const Text(
              'Questo punto non è identificato come singolo cassonetto: la telemetria dimostrativa non si applica.',
            ),
          ],
          if (point.materials.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Prima di conferire', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text(
              'Controlla i simboli sul contenitore e le regole del tuo comune. Non abbandonare rifiuti all’esterno del punto.',
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onReport();
            },
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Segnala un problema'),
          ),
          const SizedBox(height: 16),
          const Text('Dati cartografici © OpenStreetMap contributors · ODbL.'),
        ],
      ),
    );
  }
}
