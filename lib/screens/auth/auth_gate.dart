import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/local_store.dart';
import '../home_shell.dart';
import '../onboarding/onboarding_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.authService,
    required this.onToggleTheme,
  });
  final AuthService authService;
  final VoidCallback onToggleTheme;
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authNavigatorKey = GlobalKey<NavigatorState>();
  late Stream<User?> _authState = widget.authService.authStateChanges();
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: _authState,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting)
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      if (snapshot.hasError)
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Impossibile verificare la sessione.'),
                TextButton(
                  onPressed: () => setState(
                    () => _authState = widget.authService.authStateChanges(),
                  ),
                  child: const Text('Riprova'),
                ),
              ],
            ),
          ),
        );
      final user = snapshot.data;
      if (user != null)
        return _AuthenticatedEntry(
          key: ValueKey(user.uid),
          user: user,
          authService: widget.authService,
          onToggleTheme: widget.onToggleTheme,
        );
      return NavigatorPopHandler<void>(
        onPopWithResult: (_) => _authNavigatorKey.currentState?.maybePop(),
        child: Navigator(
          key: _authNavigatorKey,
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => LoginScreen(
              authService: widget.authService,
              onToggleTheme: widget.onToggleTheme,
            ),
          ),
        ),
      );
    },
  );
}

class _AuthenticatedEntry extends StatefulWidget {
  const _AuthenticatedEntry({
    super.key,
    required this.user,
    required this.authService,
    required this.onToggleTheme,
  });
  final User user;
  final AuthService authService;
  final VoidCallback onToggleTheme;
  @override
  State<_AuthenticatedEntry> createState() => _AuthenticatedEntryState();
}

class _AuthenticatedEntryState extends State<_AuthenticatedEntry> {
  late final _store = LocalStore(widget.user.uid);
  late Future<bool> _completed = _store.onboardingCompleted();
  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _completed,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting)
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      if (snapshot.hasError)
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Impossibile leggere le preferenze.'),
                TextButton(
                  onPressed: () {
                    final completed = _store.onboardingCompleted();

                    setState(() {
                      _completed = completed;
                    });
                  },
                  child: const Text('Riprova'),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await widget.authService.signOut();
                    } catch (_) {
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Impossibile uscire.')),
                        );
                    }
                  },
                  child: const Text('Esci'),
                ),
              ],
            ),
          ),
        );
      if (snapshot.data != true)
        return OnboardingScreen(
          store: _store,
          warning: widget.authService.registrationWarning,
          onComplete: () {
            setState(() {
              _completed = Future.value(true);
            });
          },
        );
      return HomeShell(
        authService: widget.authService,
        onToggleTheme: widget.onToggleTheme,
        user: widget.user,
        store: _store,
      );
    },
  );
}
