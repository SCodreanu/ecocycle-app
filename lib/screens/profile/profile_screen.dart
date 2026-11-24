import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    required this.authService,
    required this.onToggleTheme,
  });
  final User user;
  final AuthService authService;
  final VoidCallback onToggleTheme;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _busy = false;
  String? _updatedName;
  void _message(String message) {
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _updatedName ?? widget.user.displayName ?? 'Utente EcoCycle';
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Il tuo profilo', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 24),
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              foregroundImage: widget.user.photoURL == null
                  ? null
                  : NetworkImage(widget.user.photoURL!),
              onForegroundImageError: widget.user.photoURL == null
                  ? null
                  : (_, _) {},
              child: Text(
                name.trim().isEmpty ? 'E' : name.trim()[0].toUpperCase(),
                style: theme.textTheme.headlineSmall,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.titleLarge),
                  Text(widget.user.email ?? 'Email non disponibile'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Account', style: theme.textTheme.titleMedium),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Modifica nome'),
          onTap: _busy ? null : _editName,
          trailing: const Icon(Icons.chevron_right),
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
        const Divider(),
        const SizedBox(height: 12),
        Text('Impostazioni', style: theme.textTheme.titleMedium),
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
