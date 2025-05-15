import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../service/fcm_service.dart';
import '../../data/repository/auth_repository.dart';

class UserProvider with ChangeNotifier {
  String? _accessToken;
  String? _refreshToken;
  int? _expiresIn;
  String? _tokenType;

  // 유저 정보
  int? _userId;
  String? _email;
  String? _username;
  String? _profileImage;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  int? get expiresIn => _expiresIn;
  String? get tokenType => _tokenType;

  int? get userId => _userId;
  String? get email => _email;
  String? get username => _username;
  String? get profileImage => _profileImage;

  bool get isLoggedIn => _accessToken != null && _accessToken!.isNotEmpty;

  void setTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    required String tokenType,
    required int userId,
    required String email,
    required String username,
    required String profileImage,
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _expiresIn = expiresIn;
    _tokenType = tokenType;
    _userId = userId;
    _email = email;
    _username = username;
    _profileImage = profileImage;
    notifyListeners();
  }

  void logout() {
    _accessToken = null;
    _refreshToken = null;
    _expiresIn = null;
    _tokenType = null;
    _userId = null;
    _email = null;
    _username = null;
    _profileImage = null;
    notifyListeners();
  }

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', _accessToken ?? '');
    await prefs.setString('refreshToken', _refreshToken ?? '');
    await prefs.setInt('expiresIn', _expiresIn ?? 0);
    await prefs.setString('tokenType', _tokenType ?? '');
    await prefs.setInt('userId', _userId ?? 0);
    await prefs.setString('email', _email ?? '');
    await prefs.setString('username', _username ?? '');
    await prefs.setString('profileImage', _profileImage ?? '');
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('accessToken');
    _refreshToken = prefs.getString('refreshToken');
    _expiresIn = prefs.getInt('expiresIn');
    _tokenType = prefs.getString('tokenType');
    _userId = prefs.getInt('userId');
    _email = prefs.getString('email');
    _username = prefs.getString('username');
    _profileImage = prefs.getString('profileImage');
    notifyListeners();
  }

  Future<void> sendFcmTokenToServer(String fcmToken) async {
    final baseUrl = dotenv.env['BASE_AIMISSION_URL']!;
    final url = Uri.parse('$baseUrl/api/user-status');
    final headers = {'Content-Type': 'application/json'};
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    while (retryCount < maxRetries) {
      try {
        print('FCM 토큰 서버 전송 시도 ${retryCount + 1}/$maxRetries');
        final response = await http.post(
          url,
          headers: headers,
          body: jsonEncode({'fcmToken': fcmToken}),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('FCM 토큰 서버 전송 성공');
          return;
        } else if (response.statusCode == 401) {
          // 토큰 만료 시 갱신 시도
          final context = FCMService.navigatorKey.currentContext;
          if (context != null) {
            final authRepository = Provider.of<AuthRepository>(context, listen: false);
            final success = await authRepository.refreshToken(context);
            if (success) {
              // 토큰 갱신 성공 시 재시도
              headers['Authorization'] = 'Bearer ${_accessToken}';
              continue;
            }
          }
        }
        
        print('FCM 토큰 서버 전송 실패: ${response.statusCode} - ${response.body}');
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(retryDelay * retryCount);
        }
      } catch (e) {
        print('FCM 토큰 서버 전송 중 오류 발생: $e');
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(retryDelay * retryCount);
        }
      }
    }
    
    if (retryCount >= maxRetries) {
      print('FCM 토큰 서버 전송 최대 재시도 횟수 초과');
    }
  }
} 