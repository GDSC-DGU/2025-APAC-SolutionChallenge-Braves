import 'dart:async';
import 'dart:convert';
import 'package:location/location.dart' as loc;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import './location_service.dart';
import 'package:provider/provider.dart';
import '../../data/repository/auth_repository.dart';
import './fcm_service.dart';

class BackgroundLocationService {
  static final loc.Location _location = loc.Location();
  static Timer? _locationTimer;

  // 위치 전송 주기 (test 1분 단위로 진행)
  static Duration _locationInterval = const Duration(minutes: 1);
  static Duration get locationInterval => _locationInterval;
  static set locationInterval(Duration value) {
    _locationInterval = value;
    // 이미 동작 중이면 즉시 반영
    if (_locationTimer != null) {
      startLocationService(interval: _locationInterval);
    }
  }

  static Future<bool> initialize() async {
    // 권한이 모두 있는지 LocationService에서 확인
    bool hasPermission = await LocationService.checkAndRequestAllPermissions();
    if (!hasPermission) {
      print('[Location] 위치 권한이 부족합니다. 백그라운드 위치 서비스가 시작되지 않습니다.');
      return false;
    }
    return true;
  }

  /// interval: 위치 전송 주기 (기본 5분)
  static Future<void> startLocationService({Duration? interval}) async {
    print('[BackgroundLocationService] 위치 서비스 시작');
    final prefs = await SharedPreferences.getInstance();
    final travelId = prefs.getString('travelId');
    print('[BackgroundLocationService] travelId: $travelId');
    if (travelId == null) return;

    // 인증 토큰 가져오기 (Provider에서 AuthRepository 사용)
    final context = FCMService.navigatorKey.currentContext;
    String? accessToken;
    if (context != null) {
      final authRepository = Provider.of<AuthRepository>(context, listen: false);
      accessToken = await authRepository.getAccessToken();
    }

    final Duration useInterval = interval ?? _locationInterval;
    _locationTimer = Timer.periodic(useInterval, (timer) async {
      try {
        final now = DateTime.now();
        if (now.hour < 9 || now.hour >= 21) {
          print('[BackgroundLocationService] 미션 전송 제한 시간(9~21시) 외, 위치 전송 생략');
          return;
        }
        final currentLocation = await _location.getLocation();
        print('[BackgroundLocationService] 위치 정보: 위도=${currentLocation.latitude}, 경도=${currentLocation.longitude}, 정확도=${currentLocation.accuracy}');
        final baseUrl = dotenv.env['BASE_AIMISSION_URL'] ?? '';
        final url = Uri.parse('$baseUrl/api/travels/$travelId/propose-ai-mission');
        final body = {
          'latitude': currentLocation.latitude,
          'longitude': currentLocation.longitude,
          'accuracy': currentLocation.accuracy,
        };
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            if (accessToken != null && accessToken.isNotEmpty)
              'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode(body),
        );
        if (response.statusCode == 200 || response.statusCode == 202) {
          print('[BackgroundLocationService] 위치 전송 성공, FCM 알림 발송 시도됨. 응답: \\${response.body}');
        } else {
          print('[BackgroundLocationService] 위치 전송 실패(서버 오류), FCM 알림 미발송. 상태코드: \\${response.statusCode}, 응답: \\${response.body}');
        }
      } catch (e) {
        print('[Location] 위치 전송 실패: $e');
      }
    });
  }

  static Future<void> stopLocationService() async {
    _locationTimer?.cancel();
    _locationTimer = null;
  }
}