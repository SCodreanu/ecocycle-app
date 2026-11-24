import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/brand_header.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authService,
    required this.onToggleTheme,
  });
  final AuthService authService;
  final VoidCallback onToggleTheme;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false, _hide = true;
  String? _error;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = AuthService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate())
      _run(
        () => widget.authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            tooltip: 'Cambia tema',
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BrandHeader(
                      title: 'Bentornato in EcoCycle',
                      subtitle: 'Accedi per esplorare i punti di raccolta e partecipare al cambiamento.',
                    ),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Registrati')),
                        ButtonSegment(value: 1, label: Text('Accedi')),
                      ],
                      selected: const {1},
                      onSelectionChanged: _loading
                          ? null
                          : (value) {
                              if (value.contains(0))
                                Navigator.of(context).push<void>(
                                  MaterialPageRoute(
                                    builder: (_) => RegisterScreen(
                                      authService: widget.authService,
                                    ),
                                  ),
                                );
                            },
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      enabled: !_loading,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: AuthService.validateEmail,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      enabled: !_loading,
                      obscureText: _hide,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _hide = !_hide),
                          icon: Icon(
                            _hide
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          tooltip: _hide
                              ? 'Mostra password'
                              : 'Nascondi password',
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Inserisci la password.'
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading
                            ? null
                            : () => Navigator.of(context).push<void>(
                                MaterialPageRoute(
                                  builder: (_) => ForgotPasswordScreen(
                                    authService: widget.authService,
                                  ),
                                ),
                              ),
                        child: const Text('Password dimenticata?'),
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _error!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: const Text('Accedi'),
                    ),
                    if (_loading) const LinearProgressIndicator(),
                    if (AuthService.googleEnabled ||
                        AuthService.appleEnabled) ...[
                      const SizedBox(height: 18),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('oppure'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (AuthService.googleEnabled)
                        OutlinedButton(
                          onPressed: _loading
                              ? null
                              : () => _run(widget.authService.signInWithGoogle),
                          child: const Text('Continua con Google'),
                        ),
                      if (AuthService.appleEnabled)
                        OutlinedButton.icon(
                          onPressed: _loading
                              ? null
                              : () => _run(widget.authService.signInWithApple),
                          icon: const Icon(Icons.apple),
                          label: const Text('Continua con Apple'),
                        ),
                    ],
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) => RegisterScreen(
                                  authService: widget.authService,
                                ),
                              ),
                            ),
                      child: const Text('Non hai un account? Registrati'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
