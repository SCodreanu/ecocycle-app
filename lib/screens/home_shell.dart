import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.authService,
    required this.onToggleTheme,
  });

  final AuthService authService;
  final VoidCallback onToggleTheme;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);

    try {
      await widget.authService.signOut();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSigningOut = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AuthService.errorMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoCycle'),
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            tooltip: isDarkMode
                ? 'Passa al tema chiaro'
                : 'Passa al tema scuro',
            icon: Icon(
              isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          IconButton(
            onPressed: _isSigningOut ? null : _signOut,
            tooltip: 'Esci',
            icon: _isSigningOut
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.recycling, size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('EcoCycle', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Hai effettuato l’accesso.',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
