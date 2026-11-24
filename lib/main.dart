import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/auth/auth_gate.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  var dark = false;
  try {
    dark =
        await SharedPreferencesAsync().getBool('ecocycle.darkTheme') ?? false;
  } catch (_) {
    /* Default theme is usable. */
  }
  runApp(EcoCycleApp(initialDark: dark));
}

class EcoCycleApp extends StatefulWidget {
  const EcoCycleApp({super.key, this.initialDark = false});
  final bool initialDark;
  @override
  State<EcoCycleApp> createState() => _EcoCycleAppState();
}

class _EcoCycleAppState extends State<EcoCycleApp> {
  late final AuthService _authService = AuthService();
  late bool _dark = widget.initialDark;
  Future<void> _themeWrite = Future.value();
  void _toggleTheme() {
    setState(() => _dark = !_dark);
    final value = _dark;
    _themeWrite = _themeWrite
        .then(
          (_) => SharedPreferencesAsync().setBool('ecocycle.darkTheme', value),
        )
        .catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'EcoCycle',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
    home: AuthGate(authService: _authService, onToggleTheme: _toggleTheme),
  );
}
