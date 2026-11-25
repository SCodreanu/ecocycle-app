import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
    : _auth = firebaseAuth ?? FirebaseAuth.instance;
  final FirebaseAuth _auth;
  static const googleEnabled = bool.fromEnvironment(
    'ECOCYCLE_GOOGLE_SIGN_IN',
    defaultValue: true,
  );
  static const appleEnabled = bool.fromEnvironment('ECOCYCLE_APPLE_SIGN_IN');
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  Future<void>? _googleInitialization;
  Completer<void>? _registration;
  String? registrationWarning;

  Stream<User?> authStateChanges() =>
      _auth.userChanges().asyncMap((user) async {
        if (user != null && _registration != null) await _registration!.future;
        return user == null ? null : _auth.currentUser;
      });
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final completion = Completer<void>();
    _registration = completion;
    registrationWarning = null;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      try {
        await credential.user?.updateDisplayName(displayName);
      } catch (_) {
        registrationWarning = 'Account creato. Non è stato possibile salvare il nome: puoi modificarlo nel profilo.';
      }
    } finally {
      _registration = null;
      completion.complete();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      if (error.code != 'user-not-found') rethrow;
    }
  }

  Future<void> _initializeGoogle() =>
      _googleInitialization ??= GoogleSignIn.instance.initialize();
  Future<void> signInWithGoogle() async {
    await _initializeGoogle();
    final account = await GoogleSignIn.instance.authenticate();
    final token = account.authentication.idToken;
    if (token == null) throw StateError('Missing Google ID token');
    await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: token),
    );
  }

  Future<void> signInWithApple() async {
    await _auth.signInWithProvider(AppleAuthProvider());
  }

  Future<void> signOut() async {
    registrationWarning = null;
    if (googleEnabled &&
        _auth.currentUser?.providerData.any(
              (p) => p.providerId == 'google.com',
            ) ==
            true) {
      try {
        await _initializeGoogle();
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        /* Firebase logout must still complete. */
      }
    }
    await _auth.signOut();
  }

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Inserisci la tua email.';
    if (!_emailPattern.hasMatch(email)) return 'Inserisci un’email valida.';
    return null;
  }

  static String errorMessage(Object error) {
    const fallback = 'Si è verificato un errore. Riprova.';
    if (error is GoogleSignInException) {
      if (error.code == GoogleSignInExceptionCode.canceled)
        return 'Accesso con Google annullato.';
      return 'Accesso con Google non riuscito. Verifica la configurazione o riprova.';
    }
    if (error is! FirebaseAuthException) return fallback;
    return switch (error.code) {
      'invalid-email' => 'Inserisci un’email valida.',
      'invalid-credential' ||
      'invalid-login-credentials' ||
      'user-not-found' ||
      'wrong-password' => 'Email o password non corrette.',
      'user-disabled' => 'Questo account è stato disattivato.',
      'email-already-in-use' || 'account-exists-with-different-credential' => 'Questa email è già associata a un account. Accedi con il metodo originale.',
      'weak-password' || 'password-does-not-meet-requirements' =>
        'La password non soddisfa i requisiti di sicurezza.',
      'network-request-failed' => 'Controlla la connessione e riprova.',
      'too-many-requests' => 'Troppi tentativi. Riprova tra qualche minuto.',
      'operation-not-allowed' => 'Questo metodo di accesso non è disponibile.',
      'web-context-canceled' => 'Accesso annullato.',
      _ => fallback,
    };
  }
}
