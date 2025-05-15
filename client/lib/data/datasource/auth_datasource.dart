import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
const String googleServerClientId = '1084481176347-kr6p9e9hrmlgpp3cvv97dlllmldc28su.apps.googleusercontent.com';

abstract class AuthDataSource {
  Future<GoogleSignInAccount?> signInWithGoogle();
  Future<void> signOutGoogle();
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveTokens(String accessToken, String refreshToken);
  Future<void> deleteTokens();
  Future<http.Response> postGoogleLogin(String idToken);
  Future<http.Response> postRefreshToken(String refreshToken);
}

class AuthDataSourceImpl implements AuthDataSource {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    serverClientId: googleServerClientId,
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String get _baseUrl => dotenv.env['BASE_LOGIN_URL'] ?? '';

  @override
  Future<GoogleSignInAccount?> signInWithGoogle() => _googleSignIn.signIn();

  @override
  Future<void> signOutGoogle() => _googleSignIn.signOut();

  @override
  Future<String?> getAccessToken() => _storage.read(key: 'accessToken');

  @override
  Future<String?> getRefreshToken() => _storage.read(key: 'refreshToken');

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'accessToken', value: accessToken);
    await _storage.write(key: 'refreshToken', value: refreshToken);
  }

  @override
  Future<void> deleteTokens() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
  }

  @override
  Future<http.Response> postGoogleLogin(String idToken) {
    return http.post(
      Uri.parse('$_baseUrl/api/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: '{"idToken": "$idToken"}',
    );
  }

  @override
  Future<http.Response> postRefreshToken(String refreshToken) {
    return http.post(
      Uri.parse('$_baseUrl/api/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: '{"refreshToken": "$refreshToken"}',
    );
  }
} 