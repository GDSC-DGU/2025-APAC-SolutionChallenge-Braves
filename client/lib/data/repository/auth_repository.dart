import '../../core/provider/user_provider.dart';
import 'package:flutter/material.dart';

abstract class AuthRepository {
  Future<bool> signInWithGoogle(BuildContext context, UserProvider userProvider);
  Future<void> logout(BuildContext context);
  Future<bool> tryAutoLogin(BuildContext context, UserProvider userProvider);
  Future<bool> refreshToken(BuildContext context);
  Future<String?> getAccessToken();
} 