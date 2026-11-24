import 'package:flutter/material.dart';

import '../../services/local_store.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key, required this.store});
  final LocalStore store;
  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  static const _initialPoints = 2840;
  static const _catalog = [
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
  late Future<List<Map<String, dynamic>>> _records = widget.store.readRecords(
    'rewards',
  );
  bool _busy = false;
  int _balance(List<Map<String, dynamic>> records) =>
      _initialPoints -
      records.fold<int>(0, (sum, r) => sum + (r['cost'] as int));
  Future<void> _redeem(
    List<Map<String, dynamic>> records,
    String id,
    String name,
    int cost,
  ) async {
    if (_busy || _balance(records) < cost || records.any((r) => r['id'] == id))
      return;
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
      final next = [
        ...records,
        {
          'id': id,
          'name': name,
          'cost': cost,
          'date': DateTime.now().toIso8601String(),
        },
      ];
      await widget.store.writeRecords('rewards', next);
      if (!mounted) return;
      setState(() {
        _records = Future.value(next);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Riscatto dimostrativo registrato.')),
      );
    } catch (error, stackTrace) {
      debugPrint('Reward redemption error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossibile salvare il riscatto. Riprova.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _records,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting)
        return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError)
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Impossibile caricare i premi.'),
              TextButton(
                onPressed: () {
                  final records = widget.store.readRecords('rewards');

                  setState(() {
                    _records = records;
                  });
                },
                child: const Text('Riprova'),
              ),
            ],
          ),
        );
      final records = snapshot.data ?? [];
      final balance = _balance(records);
      final theme = Theme.of(context);
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('I tuoi premi', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 6),
          const Text('Programma fedeltà dimostrativo'),
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
                Text('Saldo disponibile', style: theme.textTheme.labelLarge),
                Text(
                  '$balance XP',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Livello 5 · 2.840 / 3.500 XP'),
                const SizedBox(height: 8),
                const LinearProgressIndicator(value: 2840 / 3500),
                const SizedBox(height: 8),
                const Text('Il livello non diminuisce con il riscatto.'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Premi disponibili', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final reward in _catalog) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Icon(reward.icon)),
              title: Text(reward.name),
              subtitle: Text('${reward.cost} XP'),
              trailing: records.any((r) => r['id'] == reward.id)
                  ? const Icon(
                      Icons.check_circle_outline,
                      semanticLabel: 'Riscattato',
                    )
                  : FilledButton.tonal(
                      onPressed: _busy || balance < reward.cost
                          ? null
                          : () => _redeem(
                              records,
                              reward.id,
                              reward.name,
                              reward.cost,
                            ),
                      child: Text(
                        balance < reward.cost ? 'XP insufficienti' : 'Riscatta',
                      ),
                    ),
            ),
            const Divider(height: 1),
          ],
          const SizedBox(height: 24),
          Text('Storico riscatti', style: theme.textTheme.titleLarge),
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Non hai ancora riscattato premi.'),
            ),
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
    },
  );
}
