import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/brand_header.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.authService});
  final AuthService authService;
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false, _completed = false;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _completed = false;
    });
    try {
      await widget.authService.sendPasswordResetEmail(_email.text.trim());
      if (mounted) setState(() => _completed = true);
    } catch (error) {
      if (mounted) setState(() => _error = AuthService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_loading,
    child: Scaffold(
      appBar: AppBar(title: const Text('Recupero password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BrandHeader(
                      title: 'Password dimenticata?',
                      subtitle: 'Inserisci il tuo indirizzo email. Ti invieremo un link per reimpostare la password se esiste un account.',
                    ),
                    TextFormField(
                      controller: _email,
                      enabled: !_loading && !_completed,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: AuthService.validateEmail,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    if (_completed) ...[
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.mark_email_read_outlined),
                        title: Text('Controlla la tua email'),
                        subtitle: Text(
                          'Se esiste un account, riceverai un link per reimpostare la password.',
                        ),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Torna al login'),
                      ),
                    ] else
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: const Text('Invia link'),
                      ),
                    if (_loading) const LinearProgressIndicator(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
