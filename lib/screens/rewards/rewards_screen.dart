import 'package:flutter/material.dart';

import '../../widgets/eco_ui.dart';

import '../../services/local_store.dart';
import '../../services/xp_service.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({
    super.key,
    required this.store,
    this.refreshRevision = 0,
    this.onXpChanged,
  });
  final LocalStore store;
  final int refreshRevision;
  final VoidCallback? onXpChanged;

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  static const _catalog = [
    (
      id: 'badge',
      name: 'Badge EcoCycle',
      cost: 150,
      icon: Icons.workspace_premium_outlined,
    ),
    (
      id: 'tree',
      name: 'Pianta un albero',
      cost: 1500,
      icon: Icons.park_outlined,
    ),
    (id: 'bike', name: 'Bike sharing', cost: 700, icon: Icons.pedal_bike),
    (id: 'bag', name: 'Eco bag', cost: 350, icon: Icons.shopping_bag_outlined),
    (
      id: 'museum',
      name: 'Ingresso museo',
      cost: 900,
      icon: Icons.museum_outlined,
    ),
    (
      id: 'transport',
      name: 'Trasporto pubblico',
      cost: 2400,
      icon: Icons.directions_bus_outlined,
    ),
    (
      id: 'energy',
      name: 'Energia verde',
      cost: 3000,
      icon: Icons.bolt_outlined,
    ),
  ];
  late final _service = XpService(widget.store);
  late Future<XpSummary> _summary = _service.load();
  bool _busy = false;

  @override
  void didUpdateWidget(covariant RewardsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshRevision != widget.refreshRevision && !_busy) {
      _summary = _service.load();
    }
  }

  void _reload() {
    setState(() {
      _summary = _service.load();
    });
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _recordRecycling() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final material = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Dichiara un riciclo'),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Attività autodichiarata, non verificata da sensori. Una attività premiata al giorno.',
              ),
            ),
            for (final material in [
              'Carta',
              'Plastica',
              'Vetro',
              'Organico',
              'Metalli',
              'Altro',
            ])
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, material),
                child: Text(material),
              ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
          ],
        ),
      );
      if (material == null || !mounted) return;
      final updated = await _service.recordRecycling(material);
      if (!mounted) return;
      setState(() {
        _summary = Future.value(updated);
      });
      widget.onXpChanged?.call();
      _message('Attività di riciclo registrata localmente.');
    } catch (_) {
      _message('Impossibile aggiornare le attività. Riprova.');
      if (mounted) _reload();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _redeem(String id, String name, int cost) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(name),
          content: Text(
            'Riscattare il premio dimostrativo per $cost XP? Non riceverai un premio commerciale reale.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Conferma'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      final updated = await _service.redeem(id, name, cost);
      if (!mounted) return;
      setState(() {
        _summary = Future.value(updated);
      });
      widget.onXpChanged?.call();
      _message('Riscatto dimostrativo registrato.');
    } catch (_) {
      _message('Impossibile completare il riscatto. Riprova.');
      if (mounted) _reload();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _history(List<Map<String, dynamic>> records) => Column(
    children: [
      for (final record in records.reversed)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history),
          title: Text(record['name'] as String),
          subtitle: Text((record['date'] as String).split('T').first),
          trailing: Text('−${record['cost']} XP'),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<XpSummary>(
    future: _summary,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError || !snapshot.hasData) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Impossibile caricare i punti XP.'),
              TextButton(onPressed: _reload, child: const Text('Riprova')),
            ],
          ),
        );
      }
      final xp = snapshot.data!;
      final theme = Theme.of(context);
      final recordedToday = xp.recycledOn(DateTime.now());
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const EcoPageHeader(
            title: 'I tuoi premi',
            subtitle: 'Programma fedeltà dimostrativo · dati locali',
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Saldo disponibile',
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                    const EcoIconBadge(icon: Icons.workspace_premium_outlined),
                  ],
                ),
                Text(
                  '${xp.balance} XP',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'XP totali: ${xp.totalXp} · Spesi: ${xp.spentXp}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Livello ${xp.level} · ${xp.totalXp % 500} / 500 XP al prossimo livello',
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: xp.levelProgress),
                const SizedBox(height: 8),
                const Text('Il livello non diminuisce con il riscatto.'),
              ],
            ),
          ),
          if (_busy) const LinearProgressIndicator(),
          const SizedBox(height: 24),
          Text('Guadagna XP', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _busy || recordedToday ? null : _recordRecycling,
            icon: const Icon(Icons.recycling),
            label: Text(
              recordedToday
                  ? 'Riciclo già registrato oggi'
                  : 'Dichiara un riciclo (+${xp.recyclingCount == 0 ? 50 : 20} XP)',
            ),
          ),
          const SizedBox(height: 8),
          const EcoNotice(
            message: 'Una attività autodichiarata al giorno. Le segnalazioni locali assegnano 50 XP al giorno al massimo.',
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Segnalazioni premiate'),
            trailing: Text('${xp.reportDays.length * 50} XP'),
          ),
          if (xp.onboardingCompleted)
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.check_circle_outline),
              title: Text('Onboarding completato'),
              trailing: Text('+100 XP'),
            ),
          const SizedBox(height: 16),
          Text('Missione', style: theme.textTheme.titleLarge),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ricicla in 3 giorni diversi · +100 XP',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: xp.missionCompleted ? 1.0 : xp.recyclingCount / 3,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    xp.missionCompleted
                        ? 'Missione completata'
                        : '${xp.recyclingCount}/3 giorni',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Premi disponibili', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          EcoMetricGrid(
            children: [
              for (final reward in _catalog)
                EcoPanel(
                  padding: const EdgeInsets.all(12),
                  color: xp.redeemed(reward.id)
                      ? theme.colorScheme.primaryContainer
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EcoIconBadge(icon: reward.icon, size: 42),
                      const SizedBox(height: 10),
                      Text(reward.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${reward.cost} XP',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (xp.redeemed(reward.id))
                        const Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 18),
                            SizedBox(width: 5),
                            Flexible(child: Text('Riscattato')),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonal(
                            onPressed: _busy || xp.balance < reward.cost
                                ? null
                                : () => _redeem(
                                    reward.id,
                                    reward.name,
                                    reward.cost,
                                  ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              minimumSize: const Size(0, 40),
                            ),
                            child: Text(
                              xp.balance < reward.cost
                                  ? 'XP insufficienti'
                                  : 'Riscatta',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Storico attività di riciclo',
            style: theme.textTheme.titleLarge,
          ),
          if (xp.activities.isEmpty) const Text('Nessuna attività registrata.'),
          for (final activity in xp.activities.reversed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.recycling),
              title: Text(activity['material'] as String),
              subtitle: Text((activity['date'] as String).split('T').first),
            ),
          const SizedBox(height: 24),
          Text('Storico riscatti', style: theme.textTheme.titleLarge),
          if (xp.redemptions.isEmpty)
            const Text('Non hai ancora riscattato premi con il nuovo sistema.'),
          _history(xp.redemptions),
          if (xp.legacyRedemptions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Archivio riscatti demo precedenti',
              style: theme.textTheme.titleMedium,
            ),
            const Text(
              'Riscatti del vecchio saldo dimostrativo: non incidono sul nuovo saldo.',
            ),
            _history(xp.legacyRedemptions),
          ],
        ],
      );
    },
  );
}
