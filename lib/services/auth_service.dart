import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
    : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      if (error.code != 'user-not-found') rethrow;
    }
  }

  Future<void> signOut() => _auth.signOut();

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Inserisci la tua email.';
    if (!_emailPattern.hasMatch(email)) return 'Inserisci un’email valida.';
    return null;
  }

  static String errorMessage(Object error) {
    const fallback = 'Si è verificato un errore. Riprova.';
    if (error is! FirebaseAuthException) return fallback;

    return switch (error.code) {
      'invalid-email' => 'Inserisci un’email valida.',
      'invalid-credential' ||
      'invalid-login-credentials' ||
      'user-not-found' ||
      'wrong-password' => 'Email o password non corrette.',
      'user-disabled' => 'Questo account è stato disattivato.',
      'email-already-in-use' => 'Questa email è già associata a un account.',
      'weak-password' || 'password-does-not-meet-requirements' =>
        'La password non soddisfa i requisiti di sicurezza.',
      'network-request-failed' => 'Controlla la connessione e riprova.',
      'too-many-requests' => 'Troppi tentativi. Riprova tra qualche minuto.',
      'operation-not-allowed' =>
        'L’accesso con email e password non è disponibile.',
      _ => fallback,
    };
  }
}
