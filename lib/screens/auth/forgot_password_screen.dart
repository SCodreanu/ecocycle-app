import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _requestCompleted = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _requestCompleted = false;
      _errorMessage = null;
    });

    String? errorMessage;
    try {
      await widget.authService.sendPasswordResetEmail(
        _emailController.text.trim(),
      );
    } catch (error) {
      errorMessage = AuthService.errorMessage(error);
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _requestCompleted = errorMessage == null;
      _errorMessage = errorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reimposta la password'),
          leading: IconButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            tooltip: 'Indietro',
            icon: const BackButtonIcon(),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: AuthService.validateEmail,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage case final message?)
                        Text(
                          message,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      if (_requestCompleted)
                        const Text(
                          'Se esiste un account con questa email, riceverai un link per reimpostare la password.',
                        ),
                      FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        child: const Text('Invia link'),
                      ),
                      if (_isLoading) const LinearProgressIndicator(),
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
}
