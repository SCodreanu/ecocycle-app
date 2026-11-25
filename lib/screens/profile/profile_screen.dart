import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../widgets/eco_ui.dart';

import '../../models/recycling_point.dart';
import '../../services/auth_service.dart';
import '../../services/favorites_controller.dart';
import '../../services/local_store.dart';
import '../../services/profile_photo_service.dart';
import '../../services/xp_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    required this.authService,
    required this.onToggleTheme,
    this.favorites,
    this.store,
    this.refreshRevision = 0,
  });

  final User user;
  final AuthService authService;
  final VoidCallback onToggleTheme;
  final FavoritesController? favorites;
  final LocalStore? store;
  final int refreshRevision;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _busy = false;
  String? _updatedName;
  Future<XpSummary>? _xp;
  final _picker = ImagePicker();
  late final _photoService = ProfilePhotoService(widget.user.uid);
  File? _localPhoto;
  bool _photoLoading = true;
  int _photoRevision = 0;

  Future<void> _loadPhoto() async {
    try {
      final file = await _photoService.load();
      if (mounted) {
        setState(() {
          _localPhoto = file;
        });
      }
    } catch (_) {
      // The provider photo or initials remain available as a fallback.
    } finally {
      if (mounted) setState(() => _photoLoading = false);
    }
  }

  Future<void> _choosePhoto() async {
    if (_busy || _photoLoading) return;
    setState(() => _busy = true);
    try {
      final selected = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 640,
        maxHeight: 640,
        imageQuality: 85,
      );
      if (!mounted || selected == null) return;
      final target = await _photoService.save(selected.path);
      await FileImage(target).evict();
      if (mounted) {
        setState(() {
          _localPhoto = target;
          _photoRevision++;
        });
        _message('Foto profilo aggiornata su questo dispositivo.');
      }
    } catch (_) {
      _message('Impossibile salvare la foto. Riprova.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removePhoto() async {
    if (_busy || _photoLoading || _localPhoto == null) return;
    setState(() => _busy = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rimuovere la foto profilo?'),
          content: const Text(
            'Tornerà visibile la foto Google, se disponibile, oppure la tua iniziale.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Rimuovi'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      final file = await _photoService.remove();
      await FileImage(file).evict();
      if (mounted) {
        setState(() {
          _localPhoto = null;
          _photoRevision++;
        });
        _message('Foto personalizzata rimossa.');
      }
    } catch (_) {
      _message('Impossibile rimuovere la foto. Riprova.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  ImageProvider? get _avatarImage {
    final local = _localPhoto;
    if (local != null) return FileImage(local);
    final url = widget.user.photoURL;
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadXp();
    _loadPhoto();
  }

  void _loadXp() {
    final store = widget.store;
    _xp = store == null ? null : XpService(store).load();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshRevision != oldWidget.refreshRevision ||
        widget.store != oldWidget.store) {
      _loadXp();
    }
  }

  Widget _xpSection() => FutureBuilder<XpSummary>(
    future: _xp,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const LinearProgressIndicator();
      }
      if (snapshot.hasError || !snapshot.hasData) {
        return TextButton(
          onPressed: () => setState(() {
            _loadXp();
          }),
          child: const Text('XP non disponibili. Riprova.'),
        );
      }
      final xp = snapshot.data!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'I tuoi progressi',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.emoji_events_outlined),
            title: Text('Livello ${xp.level}'),
            subtitle: Text(
              '${xp.totalXp} XP totali · ${xp.balance} XP disponibili',
            ),
          ),
          LinearProgressIndicator(value: xp.levelProgress),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.recycling),
            title: const Text('Giornate di riciclo dichiarate'),
            trailing: Text('${xp.recyclingCount}'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Giornate con segnalazioni premiate'),
            trailing: Text('${xp.reportDays.length}'),
          ),
          const Text('Progressi dimostrativi salvati sul dispositivo.'),
        ],
      );
    },
  );

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _signOut() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.authService.signOut();
    } catch (error) {
      _message(AuthService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editName() async {
    var editedName = _updatedName ?? widget.user.displayName ?? '';
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifica nome'),
        content: TextFormField(
          initialValue: editedName,
          onChanged: (value) => editedName = value,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Nome e cognome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, editedName.trim()),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    if (!mounted || name == null || name.isEmpty) return;
    setState(() => _busy = true);
    try {
      await widget.user.updateDisplayName(name);
      if (mounted) setState(() => _updatedName = name);
      _message('Nome aggiornato.');
    } catch (error) {
      _message(AuthService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeFavorite(
    FavoritesController favorites,
    RecyclingPoint point,
  ) async {
    if (!favorites.contains(point)) return;
    final saved = await favorites.toggle(point);
    _message(
      saved
          ? 'Rimosso dai preferiti.'
          : 'Impossibile aggiornare i preferiti. Riprova.',
    );
  }

  Widget _favoritesSection(FavoritesController favorites) {
    return ListenableBuilder(
      listenable: favorites,
      builder: (context, _) {
        final theme = Theme.of(context);
        final points = favorites.points;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cassonetti preferiti${favorites.ready ? ' (${points.length})' : ''}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (favorites.loading)
              const LinearProgressIndicator()
            else if (favorites.loadFailed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Impossibile leggere i preferiti.'),
                trailing: TextButton(
                  onPressed: () => favorites.load(),
                  child: const Text('Riprova'),
                ),
              )
            else if (points.isEmpty)
              const Text(
                'Nessun cassonetto salvato. Usa il cuore nel dettaglio di un cassonetto per aggiungerlo.',
              )
            else ...[
              const Text(
                'Usa il filtro Solo preferiti nella mappa per aprire i punti ancora presenti nei dati OpenStreetMap.',
              ),
              const SizedBox(height: 8),
              for (final point in points)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.favorite,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(point.title),
                  subtitle: Text(
                    [
                      point.address ?? 'OSM ${point.key}',
                      if (point.materials.isNotEmpty)
                        point.materials.join(' · '),
                    ].join('\n'),
                  ),
                  trailing: IconButton(
                    tooltip: 'Rimuovi dai preferiti',
                    onPressed: favorites.saving || _busy
                        ? null
                        : () => _removeFavorite(favorites, point),
                    icon: const Icon(Icons.close),
                  ),
                ),
            ],
            if (favorites.saving) const LinearProgressIndicator(),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _updatedName ?? widget.user.displayName ?? 'Utente EcoCycle';
    final favorites = widget.favorites;
    final avatar = _avatarImage;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const EcoPageHeader(
          title: 'Il tuo profilo',
          subtitle: 'Gestisci il tuo account e i tuoi preferiti.',
        ),
        const SizedBox(height: 18),
        EcoPanel(
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    key: ValueKey(_photoRevision),
                    radius: 36,
                    foregroundImage: avatar,
                    onForegroundImageError: avatar == null ? null : (_, _) {},
                    child: Text(
                      name.trim().isEmpty ? 'E' : name.trim()[0].toUpperCase(),
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  Positioned(
                    right: -6,
                    bottom: -6,
                    child: IconButton.filledTonal(
                      tooltip: 'Modifica foto profilo',
                      onPressed: _busy || _photoLoading ? null : _choosePhoto,
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleLarge),
                    Text(
                      widget.user.email ?? 'Email non disponibile',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Account', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        EcoPanel(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Modifica nome'),
                onTap: _busy ? null : _editName,
                trailing: const Icon(Icons.chevron_right),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.image_outlined),
                title: const Text('Modifica foto profilo'),
                subtitle: const Text('Salvata su questo dispositivo'),
                onTap: _busy || _photoLoading ? null : _choosePhoto,
                trailing: const Icon(Icons.chevron_right),
              ),
              if (_localPhoto != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Rimuovi foto personalizzata'),
                  onTap: _busy || _photoLoading ? null : _removePhoto,
                ),
              if (widget.user.email != null &&
                  widget.user.providerData.any(
                    (provider) => provider.providerId == 'password',
                  ))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Reimposta password'),
                  onTap: _busy
                      ? null
                      : () async {
                          setState(() => _busy = true);
                          try {
                            await widget.authService.sendPasswordResetEmail(
                              widget.user.email!,
                            );
                            _message(
                              'Se l’account esiste, riceverai un link di reset.',
                            );
                          } catch (error) {
                            _message(AuthService.errorMessage(error));
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                ),
            ],
          ),
        ),
        if (_xp != null) ...[
          const SizedBox(height: 16),
          EcoPanel(child: _xpSection()),
        ],
        if (favorites != null) ...[
          const SizedBox(height: 16),
          EcoPanel(child: _favoritesSection(favorites)),
        ],
        const Divider(),
        const SizedBox(height: 12),
        Text('Impostazioni', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        EcoPanel(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Tema scuro'),
                value: theme.brightness == Brightness.dark,
                onChanged: (_) => widget.onToggleTheme(),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline),
                title: const Text('Informazioni su EcoCycle'),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'EcoCycle',
                  applicationVersion: '1.0',
                  applicationIcon: Image.asset('assets/eco.png', width: 44),
                  children: [
                    const Text(
                      'Progetto ITS. Dati geografici da OpenStreetMap / Overpass. Stati, premi e segnalazioni sono dimostrativi; nessun servizio IoT reale.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _busy ? null : _signOut,
          icon: const Icon(Icons.logout),
          label: const Text('Esci dall’account'),
        ),
        if (_busy) const LinearProgressIndicator(),
      ],
    );
  }
}
