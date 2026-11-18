import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../home_shell.dart';
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
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Impossibile verificare la sessione.'),
                  TextButton(
                    onPressed: () => setState(() {
                      _authState = widget.authService.authStateChanges();
                    }),
                    child: const Text('Riprova'),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          return HomeShell(
            authService: widget.authService,
            onToggleTheme: widget.onToggleTheme,
          );
        }

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
}
