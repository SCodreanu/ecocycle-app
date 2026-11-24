import 'package:flutter/material.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, required this.title, required this.subtitle});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/eco.png',
          height: 78,
          width: 78,
          semanticLabel: 'Logo EcoCycle',
        ),
        const SizedBox(height: 24),
        Text(title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}
