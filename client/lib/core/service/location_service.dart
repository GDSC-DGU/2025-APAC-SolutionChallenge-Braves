import 'package:location/location.dart' as loc;
import '../../data/repository/trip_repository_impl.dart';
import '../../data/datasource/trip_datasource.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  static final loc.Location _location = loc.Location();

  /// 모든 위치 권한(포그라운드+백그라운드) 요청
  static Future<bool> checkAndRequestAllPermissions() async {
    // 위치 서비스 활성화
    if (!await _location.serviceEnabled()) {
      if (!await _location.requestService()) return false;
    }
    // 위치 권한 요청
    var permission = await _location.hasPermission();
    if (permission == loc.PermissionStatus.denied) {
      permission = await _location.requestPermission();
      if (permission == loc.PermissionStatus.denied) return false;
    }
    if (permission == loc.PermissionStatus.deniedForever) return false;
    // 백그라운드 권한 요청
    if (!await _location.isBackgroundModeEnabled()) {
      try {
        await _location.enableBackgroundMode(enable: true);
      } catch (e) {
        print('[Location] 백그라운드 위치 권한 요청 실패: $e');
        return false;
      }
    }
    return true;
  }

  /// 위치 권한을 확인하고, 없으면 요청합니다.
  Future<bool> checkAndRequestPermission() async {
    return await LocationService.checkAndRequestAllPermissions();
  }

  /// 현재 위치를 가져옵니다.
  Future<loc.LocationData?> getCurrentPosition() async {
    bool hasPermission = await checkAndRequestPermission();
    if (!hasPermission) return null;
    final locationData = await _location.getLocation();
    print('[LocationService] 위치 정보: 위도=${locationData.latitude}, 경도=${locationData.longitude}, 정확도=${locationData.accuracy}');
    return locationData;
  }

  /// 위치 변경 스트림을 반환합니다.
  Stream<loc.LocationData>? getPositionStream() {
    return _location.onLocationChanged;
  }

  /// 백그라운드에서 위치를 가져와 서버로 전송하는 static 메서드 (Workmanager용)
  // static Future<void> sendLocationInBackground(Map<String, dynamic> inputData) async {
  //   // travelId는 inputData에서 받아옴
  //   final travelId = inputData['travelId'] as String?;
  //   if (travelId == null) return;
  //   // 위치 권한 체크 없이 시도 (백그라운드)
  //   final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  //   final latitude = position.latitude;
  //   final longitude = position.longitude;
  //   final accuracy = position.accuracy;
  //   // 환경변수에서 BASE_AIMISSION_URL
  //   final baseUrl = dotenv.env['BASE_AIMISSION_URL']!;
  //   final url = Uri.parse('$baseUrl/api/travels/$travelId/propose-ai-mission');
  //   final body = {
  //     'latitude': latitude,
  //     'longitude': longitude,
  //     'accuracy': accuracy,
  //   };
  //   await http.post(
  //     url,
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode(body),
  //   );
  // }
} 