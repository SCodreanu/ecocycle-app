import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/bin_status.dart';
import '../../models/recycling_point.dart';
import '../../services/favorites_controller.dart';
import '../../services/navigation_service.dart';

class BinDetailScreen extends StatelessWidget {
  const BinDetailScreen({
    super.key,
    required this.point,
    required this.onReport,
    this.alternatives = const [],
    this.onAlternativeSelected,
    this.favorites,
  });

  final RecyclingPoint point;
  final VoidCallback onReport;
  final List<RecyclingPoint> alternatives;
  final ValueChanged<RecyclingPoint>? onAlternativeSelected;
  final FavoritesController? favorites;

  Future<void> _openDirections(BuildContext context) async {
    final opened = await NavigationService.openDirections(point);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile aprire le indicazioni stradali.'),
        ),
      );
    }
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    FavoritesController controller,
  ) async {
    final saved = await controller.toggle(point);
    if (!context.mounted) return;
    final message = !saved
        ? 'Impossibile aggiornare i preferiti. Riprova.'
        : controller.contains(point)
        ? 'Aggiunto ai preferiti.'
        : 'Rimosso dai preferiti.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _favoriteAction(FavoritesController controller) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.loadFailed) {
          return IconButton(
            tooltip: 'Riprova a caricare i preferiti',
            onPressed: () => controller.load(),
            icon: const Icon(Icons.refresh),
          );
        }
        if (controller.loading || controller.saving) {
          return const Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final selected = controller.contains(point);
        return IconButton(
          tooltip: selected ? 'Rimuovi dai preferiti' : 'Aggiungi ai preferiti',
          onPressed: controller.ready
              ? () => _toggleFavorite(context, controller)
              : null,
          icon: Icon(
            selected ? Icons.favorite : Icons.favorite_border,
            color: selected ? Theme.of(context).colorScheme.primary : null,
          ),
        );
      },
    );
  }

  double _distanceTo(RecyclingPoint alternative) {
    return Geolocator.distanceBetween(
          point.latitude,
          point.longitude,
          alternative.latitude,
          alternative.longitude,
        ) /
        1000;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final demo = BinStatusData.forPoint(point);
    final occupiedVolume = demo.capacity * demo.fillLevel / 100;
    final availableVolume = demo.capacity - occupiedVolume;
    final controller = favorites;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettaglio punto'),
        actions: [
          if (point.isContainer && controller != null)
            _favoriteAction(controller),
        ],
      ),
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
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _openDirections(context),
            icon: const Icon(Icons.directions_walk),
            label: const Text('Indicazioni stradali'),
          ),
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
          // Simulated telemetry applies only to individual containers.
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
              title: const Text('Capacità totale'),
              trailing: Text('${demo.capacity} L'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.inventory_outlined),
              title: const Text('Volume occupato'),
              trailing: Text('${occupiedVolume.toStringAsFixed(1)} L'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.space_dashboard_outlined),
              title: const Text('Volume residuo'),
              trailing: Text('${availableVolume.toStringAsFixed(1)} L'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.scale_outlined),
              title: const Text('Peso stimato'),
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
                  'Non rappresenta una condizione verificata sul posto. Il volume residuo non garantisce la disponibilità del cassonetto.',
                ),
              ),
          ] else ...[
            const SizedBox(height: 20),
            const Text(
              'Questo punto non è identificato come singolo cassonetto: la telemetria dimostrativa non si applica.',
            ),
          ],
          if (point.isContainer) ...[
            const SizedBox(height: 28),
            Text(
              'Alternative nelle vicinanze',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (point.materials.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Materiali non disponibili'),
                  subtitle: Text(
                    'Non è possibile individuare alternative compatibili perché i materiali accettati non sono censiti in OpenStreetMap.',
                  ),
                ),
              )
            else ...[
              Text(
                'Cassonetti con almeno un materiale in comune entro 3 km da questo punto.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Disponibilità simulata · distanze in linea d’aria.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (alternatives.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Nessuna alternativa compatibile trovata tra i punti di raccolta caricati.',
                    ),
                  ),
                )
              else
                ...alternatives.map((alternative) {
                  final alternativeDemo = BinStatusData.forPoint(alternative);
                  final sharedMaterials = alternative.materials
                      .where((material) => point.materials.contains(material))
                      .join(' · ');
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        backgroundColor: alternativeDemo.status.color,
                        foregroundColor: Colors.white,
                        child: Icon(alternativeDemo.status.icon),
                      ),
                      title: Text(alternative.title),
                      subtitle: Text(
                        '${alternative.address ?? 'OSM ${alternative.key}'}\n'
                        '$sharedMaterials\n'
                        '${alternativeDemo.status.label} · ${alternativeDemo.fillLevel}% (demo)\n'
                        '${_distanceTo(alternative).toStringAsFixed(2)} km',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: onAlternativeSelected == null
                          ? null
                          : () => onAlternativeSelected!(alternative),
                    ),
                  );
                }),
            ],
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
          OutlinedButton.icon(
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
