import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/recycling_point.dart';
import '../../services/local_store.dart';

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
      final point = _point;
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
        'category': _category,
        'description': _description.text.trim(),
        'point': point?.key,
        'latitude': _position?.latitude ?? point?.latitude,
        'longitude': _position?.longitude ?? point?.longitude,
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
          content: const Text(
            'La segnalazione è stata registrata solo su questo dispositivo. Non è stata inviata a un ente o gestore. La prima segnalazione del giorno assegna 50 XP dimostrativi.',
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

  void _showRecord(
    Map<String, dynamic> record,
  ) => Navigator.of(context).push<void>(
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
            Text((record['date'] as String).split('T').first),
            const SizedBox(height: 12),
            Text(record['description'] as String),
            if (record['point'] != null) Text('Punto OSM: ${record['point']}'),
            if (record['latitude'] != null)
              Text('Coordinate: ${record['latitude']}, ${record['longitude']}'),
            const SizedBox(height: 12),
            if (record['photo'] case final String photo)
              Image.file(
                File(photo),
                errorBuilder: (_, _, _) => const Text('Foto non disponibile'),
              ),
            const SizedBox(height: 12),
            const Text('Salvata sul dispositivo · non inviata'),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Segnala un problema', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text(
          'Registra una segnalazione sul dispositivo. Nessun invio esterno.',
        ),
        const SizedBox(height: 20),
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey(_formRevision),
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Tipologia'),
                items: _categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _category = value),
                validator: (value) =>
                    value == null ? 'Seleziona una tipologia.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                enabled: !_busy,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Descrizione',
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Descrivi il problema.'
                    : null,
              ),
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
              OutlinedButton.icon(
                onPressed: _busy ? null : _locate,
                icon: const Icon(Icons.my_location),
                label: const Text('Allega posizione attuale'),
              ),
              const SizedBox(height: 12),
              Text('Allegato fotografico', style: theme.textTheme.titleMedium),
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
                  onPressed: _busy ? null : () => setState(() => _photo = null),
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
                    onPressed: _busy ? null : () => _pick(ImageSource.gallery),
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
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.flag_outlined),
                    title: Text(record['category'] as String),
                    subtitle: Text(
                      '${(record['date'] as String).split('T').first} · Salvata localmente',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showRecord(record),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
