import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mission.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'trip_datasource.dart';
import 'package:flutter/material.dart';
import '../../../data/repository/auth_repository.dart';
import 'package:image_picker/image_picker.dart';

abstract class MissionDataSource {
  Future<List<Mission>> fetchMissions(int travelId);
  Future<Map<String, dynamic>> uploadMissionImage(
      int missionId, XFile image, BuildContext context);
  Future<Map<String, dynamic>> updateMissionImage(
      int missionId, XFile image, BuildContext context);
  Future<Map<String, dynamic>> completeMission(
      int missionId, BuildContext context);
  Future<Map<String, dynamic>> generateDirectAIMission(
      int travelId, double latitude, double longitude, {double? accuracy});
  Future<Map<String, dynamic>> acceptMissionProposal(String proposalId);
}

class MissionDataSourceImpl implements MissionDataSource {
  final String baseUrl = dotenv.env['BASE_MISSION_URL']!;
  final String baseImageUrl = dotenv.env['BASE_MISSION_IMAGE_URL']!;
  final String baseAIMissionUrl = dotenv.env['BASE_AIMISSION_URL']!;
  final AuthRepository authRepository;
  late final http.Client _client;

  MissionDataSourceImpl(this.authRepository, BuildContext context) {
    _client = AuthClient(authRepository, context);
  }

  @override
  Future<List<Mission>> fetchMissions(int travelId) async {
    final response =
        await _client.get(Uri.parse('$baseUrl/api/travels/$travelId/missions'));
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final List<dynamic> data = body['missionList'];
      return data.map((e) => Mission.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load missions');
    }
  }

  @override
  Future<Map<String, dynamic>> uploadMissionImage(
      int missionId, XFile image, BuildContext context) async {
    final url =
        Uri.parse('$baseImageUrl/api/missions/$missionId/completion-image');
    final request = http.MultipartRequest('POST', url);
    request.files
        .add(await http.MultipartFile.fromPath('image_file', image.path));
    // 인증 헤더 추가
    final accessToken = await authRepository.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    print('이미지 업로드 응답: ${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('이미지 업로드 실패: ${response.statusCode} ${response.body}');
    }
  }

  @override
  Future<Map<String, dynamic>> updateMissionImage(
      int missionId, XFile image, BuildContext context) async {
    final url =
        Uri.parse('$baseImageUrl/api/missions/$missionId/completion-image');
    final request = http.MultipartRequest('PUT', url);
    request.files
        .add(await http.MultipartFile.fromPath('image_file', image.path));
    // 인증 헤더 추가
    final accessToken = await authRepository.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('이미지 수정 실패: ${response.statusCode} ${response.body}');
    }
  }

  @override
  Future<Map<String, dynamic>> completeMission(
      int missionId, BuildContext context) async {
    final url = Uri.parse('$baseUrl/api/missions/$missionId/complete');
    final request = http.Request('PUT', url);
    // 인증 헤더 추가
    final accessToken = await authRepository.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }
    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('미션 완료 실패: ${response.statusCode} ${response.body}');
    }
  }

  /// generateDirectAIMission은 background_locator_2가 아닌 foreground(버튼 클릭 등)에서 geolocator로 위치를 받아 호출해야 함
  @override
  Future<Map<String, dynamic>> generateDirectAIMission(
      int travelId, double latitude, double longitude, {double? accuracy}) async {
    final url = Uri.parse('$baseAIMissionUrl/api/travels/$travelId/generate-direct-ai-mission');
    final body = {
      'latitude': latitude,
      'longitude': longitude,
    };
    if (accuracy != null) {
      body['accuracy'] = accuracy;
    }
    final accessToken = await authRepository.getAccessToken();
    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      },
      body: json.encode(body),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('AI 미션 생성 실패: \\${response.statusCode} \\${response.body}');
    }
  }

  @override
  Future<Map<String, dynamic>> acceptMissionProposal(String proposalId) async {
    final url = Uri.parse('$baseAIMissionUrl/api/mission-proposals/$proposalId/accept');
    final accessToken = await authRepository.getAccessToken();
    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('미션 수락 실패: \\${response.statusCode} \\${response.body}');
    }
  }
}
