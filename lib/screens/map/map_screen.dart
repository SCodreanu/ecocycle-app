import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../widgets/eco_ui.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/bin_status.dart';
import '../../models/recycling_point.dart';
import '../../services/favorites_controller.dart';
import '../../services/map_filter_service.dart';
import '../../services/recycling_service.dart';
import '../../widgets/eco_loader.dart';
import '../../widgets/map/map_markers.dart';
import 'bin_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.onReport,
    this.service,
    this.favorites,
  });
  final ValueChanged<RecyclingPoint> onReport;
  final RecyclingService? service;
  final FavoritesController? favorites;
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final _service = widget.service ?? RecyclingService();
  MapController _controller = MapController();
  late Future<List<RecyclingPoint>> _points;
  late TileLayer _tileLayer = _createTileLayer();
  TileLayer _createTileLayer() => TileLayer(
    errorTileCallback: (_, _, _) {
      if (mounted && !_tileFailed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_tileFailed) setState(() => _tileFailed = true);
        });
        WidgetsBinding.instance.ensureVisualUpdate();
      }
    },
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    tileProvider: NetworkTileProvider(
      headers: {
        if (bool.fromEnvironment('dart.library.io'))
          'User-Agent':
              'EcoCycle/1.0 (+https://github.com/SCodreanu/ecocycle-app)',
      },
    ),
  );
  LatLng? _userLocation;
  bool _locating = false, _list = false, _tileFailed = false;
  String _query = '', _material = '';
  bool _onlyFavorites = false;
  int _zoomBucket = 12;
  BinStatus? _status;
  String _locationMessage = 'Posizione non richiesta';
  Future<bool> Function()? _settings;
  bool get _supportsLocation =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  void initState() {
    super.initState();
    _points = _service.fetchRecyclingPoints();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _retry() => setState(() {
    _tileFailed = false;
    _points = _service.fetchRecyclingPoints();
  });
  void _retryFromEmptyOrError() {
    _controller.dispose();
    _controller = MapController();
    _zoomBucket = 12;
    _tileLayer = _createTileLayer();
    _retry();
  }

  Future<void> _openAttribution() async {
    try {
      if (await launchUrl(
        Uri.parse('https://www.openstreetmap.org/copyright'),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('https://www.openstreetmap.org/copyright'),
        ),
      );
    }
  }

  void _locationState(String message, [Future<bool> Function()? settings]) {
    if (mounted) {
      setState(() {
        _locationMessage = message;
        _settings = settings;
        if (message != 'Posizione disponibile') _userLocation = null;
      });
    }
  }

  Future<void> _centerOnUser() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _settings = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _locationState(
          'Localizzazione disattivata',
          Geolocator.openLocationSettings,
        );
        return;
      }
      if (!mounted) return;
      var permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) return;
      if (permission == LocationPermission.deniedForever) {
        _locationState(
          'Permesso negato definitivamente',
          Geolocator.openAppSettings,
        );
        return;
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        _locationState('Permesso negato. Riprova.');
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
      final inCoverage = RecyclingService.isWithinCoverage(
        location.latitude,
        location.longitude,
      );
      setState(() {
        _userLocation = location;
        _locationMessage = inCoverage ? 'Posizione disponibile' : 'Sei fuori dall’area coperta. I punti disponibili sono quelli di Torino e dintorni.';
      });
      if (!_list) {
        if (inCoverage) {
          _controller.move(location, _controller.camera.zoom);
        } else {
          _controller.move(const LatLng(45.07, 7.675), 12);
        }
      }
    } on LocationServiceDisabledException {
      _locationState(
        'Localizzazione disattivata',
        Geolocator.openLocationSettings,
      );
    } catch (_) {
      _locationState('Posizione non disponibile. Riprova.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _openSettings() async {
    try {
      if (await _settings?.call() == true) return;
    } catch (_) {
      /* The user can open Android settings manually. */
    }
    _locationState('Impossibile aprire le impostazioni.');
  }

  void _detail(RecyclingPoint point, List<RecyclingPoint> allPoints) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BinDetailScreen(
          point: point,
          favorites: widget.favorites,
          alternatives: MapFilterService.findAlternatives(point, allPoints),
          onAlternativeSelected: (alternative) {
            Navigator.of(context).pop();
            _detail(alternative, allPoints);
          },
          onReport: () => widget.onReport(point),
        ),
      ),
    );
  }

  void _preview(RecyclingPoint point, List<RecyclingPoint> allPoints) {
    final demo = BinStatusData.forPoint(point);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    EcoIconBadge(
                      icon: point.isContainer
                          ? demo.status.icon
                          : Icons.recycling,
                      color: point.isContainer ? demo.status.color : null,
                      size: 48,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        point.title,
                        style: Theme.of(sheet).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(point.address ?? 'Indirizzo non censito'),
                Text(
                  point.materials.isEmpty
                      ? 'Materiali non disponibili'
                      : point.materials.join(' · '),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (point.isContainer) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(demo.status.icon, color: demo.status.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${demo.status.label} · ${demo.fillLevel}%',
                        ),
                      ),
                      const Text('Demo'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: demo.fillLevel / 100,
                    color: demo.status.color,
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    Navigator.of(sheet).pop();
                    _detail(point, allPoints);
                  },
                  child: const Text('Vedi dettaglio'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(sheet).pop();
                    widget.onReport(point);
                  },
                  child: const Text('Segnala un problema'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pointRow(RecyclingPoint point, List<RecyclingPoint> allPoints) {
    final demo = BinStatusData.forPoint(point);
    return ListTile(
      leading: EcoIconBadge(
        icon: point.isContainer ? demo.status.icon : Icons.recycling,
        color: point.isContainer ? demo.status.color : null,
      ),
      title: Text(point.title),
      subtitle: Text(
        [
          point.address ?? 'Indirizzo non censito',
          if (point.isContainer)
            '${demo.status.label} · ${demo.fillLevel}% (demo)',
          if (point.materials.isNotEmpty) point.materials.join(' · '),
          if (_userLocation case final loc?)
            '${(Geolocator.distanceBetween(loc.latitude, loc.longitude, point.latitude, point.longitude) / 1000).toStringAsFixed(1)} km in linea d’aria',
        ].join('\n'),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.favorites?.contains(point) == true)
            Icon(Icons.favorite, color: Theme.of(context).colorScheme.primary),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => _detail(point, allPoints),
    );
  }

  Future<void> _chooseMaterial(List<String> materials, String active) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheet).height * .72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  'Materiali',
                  style: Theme.of(sheet).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final material in ['', ...materials])
                      ListTile(
                        title: Text(
                          material.isEmpty ? 'Tutti i materiali' : material,
                        ),
                        trailing: active == material
                            ? const Icon(Icons.check_circle_outline)
                            : null,
                        onTap: () => Navigator.of(sheet).pop(material),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted && result != null) setState(() => _material = result);
  }

  Future<void> _chooseStatus() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'Stato del cassonetto',
                style: Theme.of(sheet).textTheme.titleLarge,
              ),
            ),
            ListTile(
              title: const Text('Tutti gli stati'),
              trailing: _status == null ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(sheet).pop(-1),
            ),
            for (final status in BinStatus.values)
              ListTile(
                leading: Icon(status.icon, color: status.color),
                title: Text(status.label),
                trailing: _status == status ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(sheet).pop(status.index),
              ),
          ],
        ),
      ),
    );
    if (mounted && result != null) {
      setState(() => _status = result == -1 ? null : BinStatus.values[result]);
    }
  }

  Widget _filterButton(String label, IconData icon, VoidCallback onTap) =>
      OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: const Size(0, 42),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.expand_more, size: 18),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final favorites = widget.favorites;
    if (favorites == null) return _buildMap(context);
    return ListenableBuilder(
      listenable: favorites,
      builder: (context, _) => _buildMap(context),
    );
  }

  Widget _loadingPoints() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EcoLoader(),
        SizedBox(height: 12),
        Text('Caricamento punti di riciclo…'),
      ],
    ),
  );

  Widget _buildMap(BuildContext context) => FutureBuilder<List<RecyclingPoint>>(
    future: _points,
    builder: (context, snapshot) {
      final waiting = snapshot.connectionState == ConnectionState.waiting;
      if (waiting && !snapshot.hasData) return _loadingPoints();
      if (snapshot.hasError) {
        return _message(
          Icons.cloud_off_outlined,
          'Impossibile caricare i punti di riciclo.',
          _retryFromEmptyOrError,
        );
      }
      final all = snapshot.data ?? const <RecyclingPoint>[];
      if (all.isEmpty && waiting) return _loadingPoints();
      if (all.isEmpty) {
        return _message(
          Icons.search_off,
          'Nessun punto di riciclo trovato nella zona di Torino.',
          _retryFromEmptyOrError,
        );
      }
      final materials = MapFilterService.availableMaterials(all);
      final activeMaterial = materials.contains(_material) ? _material : '';
      final location = _userLocation;
      final points = MapFilterService.filter(
        all,
        query: _query,
        material: activeMaterial,
        status: _status,
        onlyFavorites: _onlyFavorites,
        isFavorite: widget.favorites?.contains,
        location: location,
      );
      final colors = Theme.of(context).colorScheme;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Cerca punto o materiale',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _locating
                      ? null
                      : () => setState(() => _list = !_list),
                  tooltip: _list ? 'Mostra mappa' : 'Mostra lista',
                  icon: Icon(_list ? Icons.map_outlined : Icons.list),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _filterButton(
                    activeMaterial.isEmpty
                        ? 'Tutti i materiali'
                        : activeMaterial,
                    Icons.recycling,
                    () => _chooseMaterial(materials, activeMaterial),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _filterButton(
                    _status?.label ?? 'Tutti gli stati',
                    Icons.tune,
                    _chooseStatus,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${points.length} punti · area di Torino',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (widget.favorites != null)
                  FilterChip(
                    label: const Text('Solo preferiti'),
                    avatar: Icon(
                      _onlyFavorites ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                    ),
                    showCheckmark: false,
                    selected: _onlyFavorites,
                    onSelected: widget.favorites!.ready
                        ? (value) => setState(() => _onlyFavorites = value)
                        : null,
                  ),
                IconButton(
                  onPressed: _locating || waiting ? null : _retry,
                  tooltip: 'Aggiorna punti',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          if (widget.favorites?.loadFailed == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(child: Text('Preferiti non disponibili.')),
                  TextButton(
                    onPressed: () => widget.favorites!.load(),
                    child: const Text('Riprova'),
                  ),
                ],
              ),
            ),
          if (_supportsLocation)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _locationMessage,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  if (_settings != null)
                    TextButton(
                      onPressed: _openSettings,
                      child: const Text('Impostazioni'),
                    ),
                ],
              ),
            ),
          if (waiting) const LinearProgressIndicator(),
          Expanded(
            child: IndexedStack(
              index: _list ? 1 : 0,
              children: [
                Stack(
                  children: [
                    FlutterMap(
                      mapController: _controller,
                      options: MapOptions(
                        initialCenter:
                            location != null &&
                                RecyclingService.isWithinCoverage(
                                  location.latitude,
                                  location.longitude,
                                )
                            ? location
                            : const LatLng(45.07, 7.675),
                        initialZoom: 12,
                        maxZoom: 19,
                        onPositionChanged: (camera, _) {
                          final zoom = camera.zoom.floor();
                          if (zoom != _zoomBucket) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && zoom != _zoomBucket) {
                                setState(() => _zoomBucket = zoom);
                              }
                            });
                          }
                        },
                        backgroundColor: colors.surface,
                      ),
                      children: [
                        ColorFiltered(
                          colorFilter:
                              Theme.of(context).brightness == Brightness.dark
                              ? const ColorFilter.matrix(<double>[
                                  .077,
                                  -.751,
                                  -.076,
                                  0,
                                  212,
                                  -.223,
                                  -.451,
                                  -.076,
                                  0,
                                  218,
                                  -.223,
                                  -.751,
                                  .224,
                                  0,
                                  216,
                                  0,
                                  0,
                                  0,
                                  1,
                                  0,
                                ])
                              : const ColorFilter.matrix(<double>[
                                  1,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0,
                                  1,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0,
                                  1,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0,
                                  1,
                                  0,
                                ]),
                          child: _tileLayer,
                        ),
                        MarkerLayer(
                          markers: [
                            ...MapMarkers.build(
                              points: points,
                              zoomBucket: _zoomBucket,
                              colors: colors,
                              onPointTap: (point) => _preview(point, all),
                              onClusterTap: (center) => _controller.move(
                                center,
                                math.min(19.0, _controller.camera.zoom + 2.0),
                              ),
                            ),
                            if (location != null)
                              Marker(
                                point: location,
                                width: 40,
                                height: 40,
                                child: CircleAvatar(
                                  backgroundColor: colors.tertiaryContainer,
                                  foregroundColor: colors.onTertiaryContainer,
                                  child: const Icon(Icons.my_location),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Column(
                        children: [
                          if (_supportsLocation)
                            IconButton.filledTonal(
                              onPressed: _locating || waiting
                                  ? null
                                  : _centerOnUser,
                              tooltip: 'Centra sulla mia posizione',
                              icon: _locating
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.my_location),
                            ),
                          IconButton.filledTonal(
                            onPressed: _locating
                                ? null
                                : () => _controller.move(
                                    const LatLng(45.07, 7.675),
                                    12,
                                  ),
                            tooltip: 'Torna all’area di Torino',
                            icon: const Icon(Icons.location_city_outlined),
                          ),
                          IconButton.filledTonal(
                            onPressed: () => showModalBottomSheet<void>(
                              context: context,
                              showDragHandle: true,
                              builder: (context) => SafeArea(
                                child: ListView(
                                  shrinkWrap: true,
                                  children: [
                                    const ListTile(
                                      title: Text(
                                        'Legenda · stati dimostrativi',
                                      ),
                                      subtitle: Text(
                                        'I cerchi numerati raggruppano più punti. Tocca per ingrandire.',
                                      ),
                                    ),
                                    for (final status in BinStatus.values)
                                      ListTile(
                                        leading: Icon(
                                          status.icon,
                                          color: status.color,
                                        ),
                                        title: Text(status.label),
                                        subtitle: Text(status.description),
                                      ),
                                    const ListTile(
                                      leading: Icon(Icons.recycling),
                                      title: Text(
                                        'Punto di riciclo senza telemetria',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            tooltip: 'Legenda',
                            icon: const Icon(Icons.info_outline),
                          ),
                        ],
                      ),
                    ),
                    if (_tileFailed)
                      Positioned(
                        bottom: 36,
                        left: 8,
                        right: 8,
                        child: Material(
                          color: colors.surface,
                          child: ListTile(
                            title: const Text(
                              'Alcune tile non sono disponibili.',
                            ),
                            trailing: TextButton(
                              onPressed: () => setState(() => _list = true),
                              child: const Text('Elenco'),
                            ),
                          ),
                        ),
                      ),
                    if (points.isEmpty)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Material(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('Nessun risultato'),
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Material(
                        color: colors.surface,
                        child: InkWell(
                          onTap: _openAttribution,
                          child: const Padding(
                            padding: EdgeInsets.all(7),
                            child: Text(
                              '© OpenStreetMap contributors',
                              style: TextStyle(
                                fontSize: 11,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                points.isEmpty
                    ? const Center(
                        child: Text('Nessun risultato per i filtri.'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        itemCount: points.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, index) =>
                            _pointRow(points[index], all),
                      ),
              ],
            ),
          ),
          if (!_list)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Stati simulati · tocca i gruppi per ingrandire',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: _locating
                        ? null
                        : () => setState(() => _list = true),
                    child: const Text('Elenco'),
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );
  Widget _message(IconData icon, String text, VoidCallback retry) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EcoIconBadge(icon: icon, size: 68),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: retry, child: const Text('Riprova')),
        ],
      ),
    ),
  );
}
