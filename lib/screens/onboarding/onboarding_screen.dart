import 'package:flutter/material.dart';

import '../../services/local_store.dart';
import '../../widgets/brand_header.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.store,
    required this.onComplete,
    this.warning,
  });
  final LocalStore store;
  final VoidCallback onComplete;
  final String? warning;
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  final _materials = <String>{};
  String _goal = 'Eco-Buddy';
  bool _saving = false;
  String? _error;
  Future<void> _finish() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.store.completeOnboarding(_materials.toList(), _goal);

      if (mounted) {
        widget.onComplete();
      }
    } catch (error, stackTrace) {
      debugPrint('Onboarding save error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Impossibile salvare le preferenze. Riprova.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: (_step + 1) / 3),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  BrandHeader(
                    title: [
                      'Ricicla meglio, ogni giorno',
                      'Cosa ricicli di più?',
                      'Il tuo obiettivo eco',
                    ][_step],
                    subtitle: [
                      'Scopri i punti di raccolta, consulta gli stati dimostrativi e registra le tue segnalazioni.',
                      'Personalizza la tua esperienza. Puoi anche saltare.',
                      'Scegli il profilo che ti rappresenta.',
                    ][_step],
                  ),
                  if (_step == 0 && widget.warning != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(widget.warning!),
                    ),
                  if (_step == 0) ...const [
                    ListTile(
                      leading: Icon(Icons.map_outlined),
                      title: Text('Esplora i punti di raccolta'),
                    ),
                    ListTile(
                      leading: Icon(Icons.flag_outlined),
                      title: Text('Registra segnalazioni locali'),
                    ),
                    ListTile(
                      leading: Icon(Icons.emoji_events_outlined),
                      title: Text('Scopri i premi dimostrativi'),
                    ),
                  ],
                  if (_step == 1)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final material in [
                          'Carta',
                          'Plastica',
                          'Vetro',
                          'Organico',
                          'Metalli',
                          'Pile',
                          'Abiti',
                        ])
                          FilterChip(
                            label: Text(material),
                            selected: _materials.contains(material),
                            onSelected: (value) => setState(() {
                              if (value) {
                                _materials.add(material);
                              } else {
                                _materials.remove(material);
                              }
                            }),
                          ),
                      ],
                    ),
                  if (_step == 2) ...[
                    for (final goal in ['Eco-Pilot', 'Eco-Hero', 'Eco-Buddy'])
                      ListTile(
                        title: Text(goal),
                        leading: Icon(
                          _goal == goal
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                        ),
                        onTap: () => setState(() => _goal = goal),
                      ),
                  ],
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
            if (_saving) const LinearProgressIndicator(),
            FilledButton(
              onPressed: _saving
                  ? null
                  : () {
                      if (_step < 2) {
                        setState(() => _step++);
                      } else {
                        _finish();
                      }
                    },
              child: Text(_step < 2 ? 'Avanti' : 'Inizia a riciclare'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _saving || _step == 0
                      ? null
                      : () => setState(() => _step--),
                  child: const Text('Indietro'),
                ),
                TextButton(
                  onPressed: _saving ? null : _finish,
                  child: const Text('Salta'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
