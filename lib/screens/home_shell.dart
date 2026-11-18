import 'package:material_ui/material_ui.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoCycle'),
        actions: [
          IconButton(
            onPressed: onToggleTheme,
            tooltip: isDarkMode
                ? 'Passa al tema chiaro'
                : 'Passa al tema scuro',
            icon: Icon(
              isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.recycling,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'EcoCycle',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Project foundation',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}