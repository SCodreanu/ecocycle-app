import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/recycling_point.dart';
import '../services/auth_service.dart';
import '../services/local_store.dart';
import 'map/map_screen.dart';
import 'rewards/rewards_screen.dart';
import 'report/report_screen.dart';
import 'profile/profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.authService,
    required this.onToggleTheme,
    required this.user,
    required this.store,
  });
  final AuthService authService;
  final VoidCallback onToggleTheme;
  final User user;
  final LocalStore store;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  RecyclingPoint? _reportPoint;
  int _reportRevision = 0;
  void _report(RecyclingPoint point) {
    if (mounted)
      setState(() {
        _reportPoint = point;
        _reportRevision++;
        _selectedIndex = 2;
      });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(
        children: [
          Image.asset('assets/eco.png', height: 30, width: 30),
          const SizedBox(width: 8),
          const Text('EcoCycle'),
        ],
      ),
      actions: [
        IconButton(
          onPressed: widget.onToggleTheme,
          tooltip: 'Cambia tema',
          icon: Icon(
            Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: IndexedStack(
        index: _selectedIndex,
        children: [
          MapScreen(onReport: _report),
          RewardsScreen(store: widget.store),
          ReportScreen(
            store: widget.store,
            point: _reportPoint,
            linkRevision: _reportRevision,
          ),
          ProfileScreen(
            user: widget.user,
            authService: widget.authService,
            onToggleTheme: widget.onToggleTheme,
          ),
        ],
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
          label: 'Mappa',
        ),
        NavigationDestination(
          icon: Icon(Icons.emoji_events_outlined),
          selectedIcon: Icon(Icons.emoji_events),
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
