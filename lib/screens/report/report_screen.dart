import 'dart:io';

import 'package:flutter/material.dart';

import '../../widgets/eco_ui.dart';

import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/recycling_point.dart';
import '../../services/local_store.dart';
import '../../services/xp_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({
    super.key,
    required this.store,
    this.point,
    this.linkRevision = 0,
    this.onXpChanged,
  });
  final LocalStore store;
  final RecyclingPoint? point;
  final int linkRevision;
  final VoidCallback? onXpChanged;
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _form = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _picker = ImagePicker();
  late Future<List<Map<String, dynamic>>> _records = widget.store.readRecords(
    'reports',
  );
  String? _category, _error;
  XFile? _photo;
  Position? _position;
  bool _busy = false, _clearPoint = false;
  int _formRevision = 0;
  static const _categories = [
    'Rifiuti abbandonati',
    'Cassonetto danneggiato',
    'Cassonetto stracolmo',
    'Odore di gas / fumo',
    'Cassonetto fuori uso',
    'Problema di raccolta',
    'Altro',
  ];
  RecyclingPoint? get _point => _clearPoint ? null : widget.point;
  @override
  void initState() {
    super.initState();
    _recoverPhoto();
  }

  @override
  void didUpdateWidget(covariant ReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.linkRevision != widget.linkRevision) {
      _clearPoint = false;
      _position = null;
    }
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _recoverPhoto() async {
    try {
      final result = await _picker.retrieveLostData();
      if (mounted && result.files?.isNotEmpty == true) {
        // Lost picker results may belong to a previous session. Require a new selection instead of attaching across users.
        setState(
          () => _error = 'Selezione interrotta. Scegli nuovamente la foto.',
        );
      }
    } catch (_) {
      /* Image selection is optional. */
    }
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final photo = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (mounted && photo != null) setState(() => _photo = photo);
    } catch (_) {
      if (mounted) setState(() => _error = 'Impossibile selezionare la foto.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _locate() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted)
          setState(
            () => _error = 'Attiva la localizzazione nelle impostazioni.',
          );
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        if (mounted)
          setState(
            () => _error = permission == LocationPermission.deniedForever
                ? 'Permesso negato definitivamente. Apri le impostazioni dell’app.'
                : 'Permesso di posizione negato.',
          );
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 30),
        ),
      );
      if (mounted) setState(() => _position = position);
    } catch (_) {
      if (mounted) setState(() => _error = 'Posizione non disponibile.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    File? copied;
    var saved = false;
    try {
      final records = await widget.store.readRecords('reports');
      final date = DateTime.now();
      final creditedDays = XpSummary.uniqueDays([
        ...records,
        ...await widget.store.readRecords('report_xp_days'),
      ]);
      final earnedXp = !creditedDays.contains(XpSummary.dayKey(date));
      final point = _point;
      final position = _position;
      final category = _category;
      final description = _description.text.trim();
      if (_photo != null) {
        final root = await getApplicationDocumentsDirectory();
        final directory = Directory(
          '${root.path}/reports/${Uri.encodeComponent(widget.store.uid)}',
        );
        await directory.create(recursive: true);
        // Keep the original encoded image bytes in private app storage.
        copied = await File(_photo!.path)
            .copy('${directory.path}/${date.microsecondsSinceEpoch}.image');
      }
      final record = <String, dynamic>{
        'id': date.microsecondsSinceEpoch.toString(),
        'date': date.toIso8601String(),
        'category': category,
        'description': description,
        'point': point?.key,
        'latitude': position?.latitude ?? point?.latitude,
        'longitude': position?.longitude ?? point?.longitude,
        'locationSource': position != null
            ? 'gps'
            : point != null
            ? 'osm'
            : null,
        'photo': copied?.path,
      };
      final next = [...records, record];
      await widget.store.writeRecords('reports', next);
      saved = true;
      if (!mounted) return;
      widget.onXpChanged?.call();
      _description.clear();
      _form.currentState?.reset();
      setState(() {
        _records = Future.value(next);
        _formRevision++;
        _category = null;
        _photo = null;
        _position = null;
        _clearPoint = true;
      });
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Segnalazione salvata'),
          content: Text(
            'La segnalazione è stata salvata solo su questo dispositivo. Nessun invio esterno.\n\n'
            '${earnedXp ? '+50 XP dimostrativi.' : 'Hai già ottenuto gli XP per una segnalazione oggi.'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Chiudi'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!saved && copied != null) {
        try {
          await copied.delete();
        } catch (_) {}
      }
      if (mounted)
        setState(
          () => _error = 'Impossibile salvare la segnalazione. Riprova.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatDate(Object? raw) {
    final date = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (date == null) return 'Data non disponibile';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} · '
        '${two(date.hour)}:${two(date.minute)}';
  }

  void _showPhoto(String path) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Fotografia')),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Text('Foto non disponibile'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPosition(double latitude, double longitude) {
    final location = LatLng(latitude, longitude);
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Posizione segnalazione')),
          body: Column(
            children: [
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: location,
                    initialZoom: 16,
                    maxZoom: 19,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      tileProvider: NetworkTileProvider(
                        headers: {
                          'User-Agent': 'EcoCycle/1.0 (+https://github.com/SCodreanu/ecocycle-app)',
                        },
                      ),
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: location,
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.location_on,
                            size: 40,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Column(
                  children: [
                    Text(
                      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
                    ),
                    TextButton(
                      onPressed: () async {
                        try {
                          final opened = await launchUrl(
                            Uri.parse(
                              'https://www.openstreetmap.org/copyright',
                            ),
                            mode: LaunchMode.externalApplication,
                          );
                          if (opened) return;
                        } catch (_) {}
                        if (context.mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'https://www.openstreetmap.org/copyright',
                              ),
                            ),
                          );
                      },
                      child: const Text('© OpenStreetMap contributors'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteRecord(Map<String, dynamic> record) async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare la segnalazione?'),
        content: const Text(
          'La segnalazione e la foto locale verranno rimosse. Gli XP già guadagnati restano invariati.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || _busy) return;
    setState(() {
      _busy = true;
    });
    try {
      final records = await widget.store.readRecords('reports');
      final matching = records.where((r) => r['id'] == record['id']).toList();
      if (matching.isEmpty) return;
      // Archive only the day before removing the source of the XP credit.
      await XpService(widget.store).preserveReportCredit(matching.first);
      final next = records.where((r) => r['id'] != record['id']).toList();
      await widget.store.writeRecords('reports', next);
      var photoRemoved = true;
      final photo = matching.first['photo'];
      if (photo is String && !next.any((r) => r['photo'] == photo)) {
        try {
          final root = await getApplicationDocumentsDirectory();
          final folder = Directory(
            '${root.path}/reports/${Uri.encodeComponent(widget.store.uid)}',
          );
          final file = File(photo);
          if (file.parent.absolute.path == folder.absolute.path &&
              await file.exists()) {
            await file.delete();
          }
        } catch (_) {
          photoRemoved = false;
        }
      }
      if (!mounted) return;
      setState(() {
        _records = Future.value(next);
      });
      widget.onXpChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            photoRemoved ? 'Segnalazione eliminata. XP invariati.' : 'Segnalazione eliminata, ma non è stato possibile rimuovere la foto.',
          ),
        ),
      );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossibile eliminare la segnalazione. Riprova.'),
          ),
        );
    } finally {
      if (mounted)
        setState(() {
          _busy = false;
        });
    }
  }

  void _showRecord(Map<String, dynamic> record) {
    final lat = record['latitude'];
    final lon = record['longitude'];
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Segnalazione locale')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                record['category'] as String,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(_formatDate(record['date'])),
              const SizedBox(height: 12),
              Text(record['description'] as String),
              if (record['point'] != null)
                Text('Punto OSM: ${record['point']}'),
              if (lat is num && lon is num) ...[
                const SizedBox(height: 12),
                Text(
                  'Coordinate: ${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}',
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      _showPosition(lat.toDouble(), lon.toDouble()),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Visualizza posizione'),
                ),
              ],
              if (record['photo'] case final String photo) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _showPhoto(photo),
                  child: Image.file(
                    File(photo),
                    errorBuilder: (_, _, _) =>
                        const Text('Foto non disponibile'),
                  ),
                ),
                TextButton(
                  onPressed: () => _showPhoto(photo),
                  child: const Text('Apri foto a schermo intero'),
                ),
              ],
              const SizedBox(height: 12),
              const Text('Salvata sul dispositivo · non inviata'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const EcoPageHeader(
          title: 'Segnala un problema',
          subtitle: 'Registra una segnalazione sul dispositivo.',
        ),
        const SizedBox(height: 12),
        const EcoNotice(
          message: 'Nessun invio esterno. I campi con * sono obbligatori; foto e posizione sono facoltative.',
        ),
        const SizedBox(height: 20),
        EcoPanel(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey(_formRevision),
                  initialValue: _category,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Tipologia *'),
                  items: _categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(
                            category,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _category = value),
                  validator: (value) =>
                      value == null ? 'Seleziona una tipologia.' : null,
                ),
                if (_category == 'Odore di gas / fumo')
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: EcoNotice(
                      warning: true,
                      icon: Icons.warning_amber_rounded,
                      message: 'Se rilevi fumo, odore di gas o un pericolo immediato, allontanati e chiama il 112 da un luogo sicuro. EcoCycle non invia richieste di soccorso.',
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  enabled: !_busy,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Descrizione *',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Descrivi il problema.'
                      : null,
                ),
                const Divider(),
                Text(
                  'Posizione (facoltativa)',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_point case final point?)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.place_outlined),
                    title: Text(point.title),
                    subtitle: Text('OSM ${point.key}'),
                    trailing: IconButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _clearPoint = true),
                      icon: const Icon(Icons.close),
                      tooltip: 'Rimuovi punto',
                    ),
                  ),
                if (_position != null)
                  Text(
                    'Posizione: ${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}',
                  ),
                if (_position != null || _point != null)
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _showPosition(
                            _position?.latitude ?? _point!.latitude,
                            _position?.longitude ?? _point!.longitude,
                          ),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Anteprima posizione'),
                  ),
                if (_position != null)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _position = null;
                          }),
                    child: const Text('Rimuovi posizione GPS'),
                  ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _locate,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Allega posizione attuale'),
                ),
                const Divider(),
                Text(
                  'Allegato fotografico (facoltativo)',
                  style: theme.textTheme.titleMedium,
                ),
                if (_photo != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_photo!.path),
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Text('Foto non disponibile'),
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => _showPhoto(_photo!.path),
                    child: const Text('Apri foto a schermo intero'),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _photo = null),
                    child: const Text('Rimuovi foto'),
                  ),
                ],
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Fotocamera'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galleria'),
                    ),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: const Text('Salva segnalazione'),
                ),
                if (_busy) const LinearProgressIndicator(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Le tue segnalazioni', style: theme.textTheme.titleLarge),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _records,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError)
              return TextButton(
                onPressed: () {
                  final records = widget.store.readRecords('reports');

                  setState(() {
                    _records = records;
                  });
                },
                child: const Text('Impossibile leggere lo storico. Riprova.'),
              );
            final records = snapshot.data ?? [];
            if (records.isEmpty)
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Non hai ancora registrato segnalazioni.'),
              );
            return Column(
              children: [
                for (final record in records.reversed)
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      leading: const EcoIconBadge(icon: Icons.flag_outlined),
                      title: Text(record['category'] as String),
                      subtitle: Text(
                        '${_formatDate(record['date'])}\nSalvata localmente${record['photo'] != null ? ' · Foto' : ''}${record['latitude'] != null ? ' · Posizione' : ''}',
                      ),
                      trailing: IconButton(
                        tooltip: 'Elimina segnalazione',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: _busy ? null : () => _deleteRecord(record),
                      ),
                      onTap: _busy ? null : () => _showRecord(record),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
