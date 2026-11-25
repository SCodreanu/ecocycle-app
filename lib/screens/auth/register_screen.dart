import 'package:flutter/material.dart';

import '../../widgets/eco_ui.dart';
import '../../services/auth_service.dart';
import '../../widgets/brand_header.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.authService});
  final AuthService authService;
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController(),
      _lastName = TextEditingController(),
      _email = TextEditingController(),
      _password = TextEditingController(),
      _confirm = TextEditingController();
  int _step = 0;
  bool _loading = false, _hidePassword = true, _hideConfirm = true;
  String? _error;
  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _lastName,
      _email,
      _password,
      _confirm,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? 'Campo obbligatorio.' : null;
  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.authService.register(
        email: _email.text.trim(),
        password: _password.text,
        displayName: '${_firstName.text.trim()} ${_lastName.text.trim()}',
      );
    } catch (error) {
      if (mounted) setState(() => _error = AuthService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_loading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Registrazione'),
          leading: IconButton(
            icon: const BackButtonIcon(),
            tooltip: 'Indietro',
            onPressed: _loading
                ? null
                : () {
                    if (_step == 1) {
                      setState(() => _step = 0);
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: EcoPanel(
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LinearProgressIndicator(value: (_step + 1) / 2),
                        const SizedBox(height: 24),
                        BrandHeader(
                          title: _step == 0
                              ? 'Crea il tuo account'
                              : 'Ci siamo quasi!',
                          subtitle: _step == 0
                              ? 'Passaggio 1 di 2 · I tuoi dati'
                              : 'Passaggio 2 di 2 · Proteggi il tuo account',
                        ),
                        if (_step == 0) ...[
                          TextFormField(
                            key: const ValueKey('firstName'),
                            controller: _firstName,
                            decoration: const InputDecoration(
                              labelText: 'Nome',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: _required,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            key: const ValueKey('lastName'),
                            controller: _lastName,
                            decoration: const InputDecoration(
                              labelText: 'Cognome',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: _required,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            key: const ValueKey('email'),
                            controller: _email,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: AuthService.validateEmail,
                          ),
                        ],
                        if (_step == 1) ...[
                          TextFormField(
                            key: const ValueKey('password'),
                            enabled: !_loading,
                            controller: _password,
                            obscureText: _hidePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              helperText: 'Almeno 8 caratteri',
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _hidePassword = !_hidePassword,
                                ),
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                tooltip: 'Mostra o nascondi password',
                              ),
                            ),
                            validator: (value) => (value ?? '').length < 8
                                ? 'Usa almeno 8 caratteri.'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            key: const ValueKey('confirm'),
                            enabled: !_loading,
                            controller: _confirm,
                            obscureText: _hideConfirm,
                            decoration: InputDecoration(
                              labelText: 'Conferma password',
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _hideConfirm = !_hideConfirm,
                                ),
                                icon: Icon(
                                  _hideConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                tooltip: 'Mostra o nascondi password',
                              ),
                            ),
                            validator: (value) => value == _password.text
                                ? null
                                : 'Le password non coincidono.',
                            onFieldSubmitted: (_) => _submit(),
                          ),
                        ],
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              _error!,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _loading ? null : _submit,
                          child: Text(_step == 0 ? 'Avanti' : 'Registrati'),
                        ),
                        if (_loading) const LinearProgressIndicator(),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Hai già un account? Accedi'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
