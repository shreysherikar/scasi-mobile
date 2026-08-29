import 'package:google_sign_in/google_sign_in.dart';
import '../config/constants.dart';
import 'supabase_service.dart';

/// Google Sign-In still gets us device-level Gmail access, but identity now
/// flows through Supabase: the Google ID token is exchanged for a Supabase
/// session (see [SupabaseService.signInWithGoogleIdToken]), and it's that
/// Supabase session token — not the Google token — that our own FastAPI
/// backend verifies on every request.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // `serverClientId` must be a Google Cloud "Web application" OAuth client
  // ID (not the Android/iOS one) — Supabase's Google provider requires the
  // ID token's audience to match a web client ID.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: kGmailScopes,
    serverClientId: kGoogleServerClientId,
  );

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  bool get isSignedIn => SupabaseService.instance.currentSession != null;

  Future<GoogleSignInAccount?> signInSilently() async {
    final account = await _googleSignIn.signInSilently();
    if (account == null) return null;
    await _exchangeForSupabaseSession(account);
    return isSignedIn ? account : null;
  }

  Future<GoogleSignInAccount?> signIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;
    await _exchangeForSupabaseSession(account);
    return account;
  }

  Future<void> signOut() async {
    await SupabaseService.instance.signOut();
    await _googleSignIn.signOut();
  }

  Future<void> _exchangeForSupabaseSession(GoogleSignInAccount account) async {
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw Exception(
        'Google did not return an ID token — check that serverClientId in '
        'constants.dart is a valid Google "Web application" OAuth client ID.',
      );
    }
    await SupabaseService.instance.signInWithGoogleIdToken(
      idToken: idToken,
      accessToken: auth.accessToken ?? '',
    );
  }

  /// Fresh Gmail access token, refreshing under the hood if needed. Used
  /// only for direct Gmail API calls — never sent to our own backend.
  Future<String?> getAccessToken() async {
    final account = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) return null;
    final auth = await account.authentication;
    return auth.accessToken;
  }
}
