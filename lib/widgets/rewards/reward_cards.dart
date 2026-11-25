import 'package:flutter/material.dart';

import '../../services/xp_service.dart';
import '../eco_ui.dart';

class XpBalanceCard extends StatelessWidget {
  const XpBalanceCard({super.key, required this.xp});

  final XpSummary xp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
    );
  }
}

class RewardMissionCard extends StatelessWidget {
  const RewardMissionCard({super.key, required this.xp});

  final XpSummary xp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
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
    );
  }
}

class RewardCard extends StatelessWidget {
  const RewardCard({
    super.key,
    required this.name,
    required this.cost,
    required this.icon,
    required this.redeemed,
    required this.balance,
    required this.busy,
    required this.onRedeem,
  });

  final String name;
  final int cost;
  final IconData icon;
  final bool redeemed;
  final int balance;
  final bool busy;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return EcoPanel(
      padding: const EdgeInsets.all(12),
      color: redeemed ? theme.colorScheme.primaryContainer : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EcoIconBadge(icon: icon, size: 42),
          const SizedBox(height: 10),
          Text(name, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '$cost XP',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          if (redeemed)
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
                onPressed: busy || balance < cost ? null : onRedeem,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  minimumSize: const Size(0, 40),
                ),
                child: Text(
                  balance < cost ? 'XP insufficienti' : 'Riscatta',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
