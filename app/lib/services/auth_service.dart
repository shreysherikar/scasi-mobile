import 'package:google_sign_in/google_sign_in.dart';
import '../config/constants.dart';

/// Pure client-side Google Sign-In. Unlike a web app, a native mobile app is
/// allowed by Google to call REST APIs directly with the access token the
/// SDK hands back — no server-side code exchange needed. The SDK also
/// silently refreshes the access token for you when you re-request
/// `.authentication` after it expires (~1hr).
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: kGmailScopes);

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Future<GoogleSignInAccount?> signInSilently() => _googleSignIn.signInSilently();

  Future<GoogleSignInAccount?> signIn() => _googleSignIn.signIn();

  Future<void> signOut() => _googleSignIn.signOut();

  /// Fresh Gmail access token, refreshing under the hood if needed.
  Future<String?> getAccessToken() async {
    final account = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) return null;
    final auth = await account.authentication;
    return auth.accessToken;
  }
}
