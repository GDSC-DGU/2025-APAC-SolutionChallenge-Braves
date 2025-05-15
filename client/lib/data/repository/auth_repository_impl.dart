import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/provider/user_provider.dart';
import 'auth_repository.dart';
import '../datasource/auth_datasource.dart';
import 'package:provider/provider.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;
  AuthResult(this.success, [this.errorMessage]);
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource dataSource;
  AuthRepositoryImpl([AuthDataSource? dataSource]) : dataSource = dataSource ?? AuthDataSourceImpl();

  Future<AuthResult> signInWithGoogleWithError(BuildContext context, UserProvider userProvider) async {
    try {
      final googleUser = await dataSource.signInWithGoogle();
      if (googleUser == null) return AuthResult(false, '구글 로그인 취소');
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) return AuthResult(false, 'idToken 없음');
      final response = await dataSource.postGoogleLogin(idToken);
      if (response.statusCode != 200) {
        return AuthResult(false, '서버 응답 오류: ${response.statusCode}');
      }
      final res = jsonDecode(response.body);
      final token = res['data']['token'];
      final user = res['data']['user'];
      userProvider.setTokens(
        accessToken: token['accessToken'],
        refreshToken: token['refreshToken'],
        expiresIn: token['expiresIn'],
        tokenType: token['tokenType'],
        userId: user['userId'],
        email: user['email'],
        username: user['username'],
        profileImage: user['profileImage']
      );
      await userProvider.saveToPrefs();
      await dataSource.saveTokens(token['accessToken'], token['refreshToken']);
      return AuthResult(true);
    } catch (e, stack) {
      debugPrint('signInWithGoogle error: $e\n$stack');
      return AuthResult(false, e.toString());
    }
  }

  @override
  Future<bool> signInWithGoogle(BuildContext context, UserProvider userProvider) async {
    final result = await signInWithGoogleWithError(context, userProvider);
    return result.success;
  }

  @override
  Future<void> logout(BuildContext context) async {
    await dataSource.signOutGoogle();
    await dataSource.deleteTokens();
    // userProvider.logout(); // 필요시 context에서 Provider로 접근
  }

  @override
  Future<bool> tryAutoLogin(BuildContext context, UserProvider userProvider) async {
    try {
      final accessToken = await dataSource.getAccessToken();
      final refreshToken = await dataSource.getRefreshToken();
      if (accessToken != null && refreshToken != null) {
        userProvider.setTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresIn: 0,
          tokenType: '',
          userId: userProvider.userId ?? 0,
          email: userProvider.email ?? '',
          username: userProvider.username ?? '',
          profileImage: userProvider.profileImage ?? ''
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('tryAutoLogin error: $e');
      return false;
    }
  }

  @override
  Future<bool> refreshToken(BuildContext context) async {
    try {
      final refreshToken = await dataSource.getRefreshToken();
      if (refreshToken == null) return false;
      final response = await dataSource.postRefreshToken(refreshToken);
      if (response.statusCode != 200) return false;
      final data = jsonDecode(response.body);
      final accessToken = data['accessToken'];
      // UserProvider의 accessToken도 갱신
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.setTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresIn: userProvider.expiresIn ?? 0,
        tokenType: userProvider.tokenType ?? '',
        userId: userProvider.userId ?? 0,
        email: userProvider.email ?? '',
        username: userProvider.username ?? '',
        profileImage: userProvider.profileImage ?? '',
      );
      await dataSource.saveTokens(accessToken, refreshToken);
      return true;
    } catch (e) {
      debugPrint('refreshToken error: $e');
      return false;
    }
  }

  @override
  Future<String?> getAccessToken() async {
    return await dataSource.getAccessToken();
  }
} 