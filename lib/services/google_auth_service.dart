import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

class GoogleAuthService extends ChangeNotifier {
  static final GoogleAuthService instance = GoogleAuthService._internal();
  GoogleAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      drive.DriveApi.driveScope, // Full access to show existing folders as chats
    ],
  );

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  auth.AuthClient? _authenticatedClient;
  auth.AuthClient? get authenticatedClient => _authenticatedClient;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) async {
      _currentUser = account;
      if (account != null) {
        _authenticatedClient = await _googleSignIn.authenticatedClient();
      } else {
        _authenticatedClient = null;
      }
      _isLoading = false;
      notifyListeners();
    });

    try {
      await _googleSignIn.signInSilently().timeout(const Duration(seconds: 1));
    } catch (e) {
      debugPrint('Silent sign in error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn() async {
    _isLoading = true;
    notifyListeners();
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        _currentUser = account;
        _authenticatedClient = await _googleSignIn.authenticatedClient();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      await _googleSignIn.signOut();
    }
    _currentUser = null;
    _authenticatedClient = null;
    _isLoading = false;
    notifyListeners();
  }
}
