import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'map/map_screen.dart';

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
  int _selectedIndex = 0;
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    if (_isSigningOut) return;

    setState(() {
      _isSigningOut = true;
    });

    try {
      await widget.authService.signOut();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSigningOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AuthService.errorMessage(error)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode =
        theme.brightness == Brightness.dark;

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
              isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          IconButton(
            onPressed:
                _isSigningOut ? null : _signOut,
            tooltip: 'Esci',
            icon: _isSigningOut
                ? const SizedBox.square(
                    dimension: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: const [
            MapScreen(),
            Center(
              child:
                  Text('Qui troverai i tuoi premi.'),
            ),
            Center(
              child: Text(
                'Qui potrai inviare una segnalazione.',
              ),
            ),
            Center(
              child:
                  Text('Qui troverai il tuo profilo.'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mappa',
          ),
          NavigationDestination(
            icon:
                Icon(Icons.emoji_events_outlined),
            selectedIcon:
                Icon(Icons.emoji_events),
            label: 'Premi',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Segnala',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profilo',
          ),
        ],
      ),
    );
  }
}