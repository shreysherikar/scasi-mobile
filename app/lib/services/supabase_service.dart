import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';

/// Thin wrapper around the Supabase client. Supabase is the identity
/// provider now: native Google Sign-In gets us a Google ID token, which we
/// hand to Supabase to mint a *Supabase* session (JWT). That Supabase JWT —
/// not the Google token — is what we send to our own FastAPI backend on
/// every request.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  static Future<void> init() => Supabase.initialize(
        url: kSupabaseUrl,
        anonKey: kSupabaseAnonKey,
      );

  SupabaseClient get client => Supabase.instance.client;

  Session? get currentSession => client.auth.currentSession;

  /// Exchanges a native Google ID token for a Supabase session.
  Future<AuthResponse> signInWithGoogleIdToken({
    required String idToken,
    required String accessToken,
  }) {
    return client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<void> signOut() => client.auth.signOut();

  /// The bearer token our own backend (see /backend) expects.
  String? get backendToken => currentSession?.accessToken;
}
