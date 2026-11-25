import 'package:flutter/material.dart';

import '../../widgets/eco_ui.dart';
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
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.store.completeOnboarding(_materials.toList(), _goal);
      if (mounted) widget.onComplete();
    } catch (error, stackTrace) {
      debugPrint('Onboarding save error: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted)
        setState(() {
          _saving = false;
          _error = 'Impossibile salvare le preferenze. Riprova.';
        });
    }
  }

  static const _choices = [
    ('Carta', Icons.description_outlined),
    ('Plastica', Icons.local_drink_outlined),
    ('Vetro', Icons.wine_bar_outlined),
    ('Organico', Icons.eco_outlined),
    ('Metalli', Icons.inventory_2_outlined),
    ('Pile', Icons.battery_charging_full),
    ('Abiti', Icons.checkroom_outlined),
  ];
  static const _goals = [
    (
      'Eco-Pilot',
      'Inizia a costruire nuove abitudini.',
      Icons.explore_outlined,
    ),
    (
      'Eco-Hero',
      'Fai del riciclo una scelta quotidiana.',
      Icons.workspace_premium_outlined,
    ),
    (
      'Eco-Buddy',
      'Fai piccoli passi, con costanza.',
      Icons.volunteer_activism_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'PASSAGGIO ${_step + 1} / 3',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _saving ? null : _finish,
                    child: const Text('Salta'),
                  ),
                ],
              ),
              Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 5,
                          decoration: BoxDecoration(
                            color: i <= _step
                                ? colors.primary
                                : colors.outlineVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
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
                        'Esplora i punti di raccolta e partecipa al cambiamento.',
                        'Scegli uno o più materiali per personalizzare la tua esperienza.',
                        'Scegli il profilo che ti rappresenta.',
                      ][_step],
                    ),
                    if (_step == 0 && widget.warning != null)
                      EcoNotice(message: widget.warning!),
                    if (_step == 0)
                      EcoPanel(
                        child: Column(
                          children: const [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: EcoIconBadge(icon: Icons.map_outlined),
                              title: Text('Esplora i punti di raccolta'),
                              subtitle: Text(
                                'Dati geografici da OpenStreetMap',
                              ),
                            ),
                            Divider(),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: EcoIconBadge(icon: Icons.flag_outlined),
                              title: Text('Registra segnalazioni locali'),
                              subtitle: Text(
                                'Con foto e posizione facoltative',
                              ),
                            ),
                            Divider(),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: EcoIconBadge(
                                icon: Icons.emoji_events_outlined,
                              ),
                              title: Text('Scopri i premi dimostrativi'),
                              subtitle: Text('Guadagna XP con le tue attività'),
                            ),
                          ],
                        ),
                      ),
                    if (_step == 1) ...[
                      EcoMetricGrid(
                        children: [
                          for (final choice in _choices)
                            FilterChip(
                              avatar: Icon(choice.$2, size: 20),
                              label: Text(choice.$1),
                              selected: _materials.contains(choice.$1),
                              onSelected: _saving
                                  ? null
                                  : (value) => setState(() {
                                      if (value) {
                                        _materials.add(choice.$1);
                                      } else {
                                        _materials.remove(choice.$1);
                                      }
                                    }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_materials.length} materiali selezionati',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    if (_step == 2) ...[
                      for (final goal in _goals)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: EcoPanel(
                            color: _goal == goal.$1
                                ? colors.primaryContainer
                                : null,
                            padding: EdgeInsets.zero,
                            child: ListTile(
                              leading: EcoIconBadge(icon: goal.$3),
                              title: Text(goal.$1),
                              subtitle: Text(goal.$2),
                              trailing: Icon(
                                _goal == goal.$1
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                              ),
                              onTap: _saving
                                  ? null
                                  : () => setState(() => _goal = goal.$1),
                            ),
                          ),
                        ),
                    ],
                    if (_error != null)
                      EcoNotice(message: _error!, warning: true),
                  ],
                ),
              ),
              if (_saving) const LinearProgressIndicator(),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _saving
                    ? null
                    : () {
                        if (_step < 2) {
                          setState(() => _step++);
                        } else {
                          _finish();
                        }
                      },
                icon: Icon(_step < 2 ? Icons.arrow_forward : Icons.check),
                label: Text(_step < 2 ? 'Avanti' : 'Inizia a riciclare'),
              ),
              TextButton(
                onPressed: _saving || _step == 0
                    ? null
                    : () => setState(() => _step--),
                child: const Text('Indietro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
