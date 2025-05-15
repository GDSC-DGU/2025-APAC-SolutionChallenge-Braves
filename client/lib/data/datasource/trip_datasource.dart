import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trip.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import '../../data/repository/auth_repository.dart';


abstract class TripDataSource {
  Future<List<Trip>> fetchTrips();
  Future<void> addTrip(Trip trip);
  Future<void> updateTrip(Trip trip);
  Future<void> deleteTrip(int tripId);
  Future<void> proposeAiMission({
    required String travelId,
    required double latitude,
    required double longitude,
    double? accuracy,
  });
}

class AuthClient extends http.BaseClient {
  final AuthRepository authRepository;
  final BuildContext context;
  final http.Client _inner;

  AuthClient(this.authRepository, this.context, [http.Client? inner]) : _inner = inner ?? http.Client();

  Future<String?> _getAccessToken() async {
    // AuthRepository에서 accessToken을 가져오는 메서드 필요
    return await authRepository.getAccessToken();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final accessToken = await _getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }
    http.StreamedResponse response = await _inner.send(request);

    if (response.statusCode == 401) {
      final refreshed = await authRepository.refreshToken(context);
      if (refreshed) {
        final newAccessToken = await _getAccessToken();
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $newAccessToken';
        }
        response = await _inner.send(request);
      } else {
        await authRepository.logout(context);
        // 필요시 로그인 화면 이동 등
      }
    }
    return response;
  }
}

class TripDataSourceImpl implements TripDataSource {
  final String baseUrl = dotenv.env['BASE_TRIP_URL']!;
  final AuthRepository authRepository;
  late final http.Client _client;

  TripDataSourceImpl(this.authRepository, BuildContext context) {
    _client = AuthClient(authRepository, context);
  }

  @override
  Future<List<Trip>> fetchTrips() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/travels'));
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final List<dynamic> data = body['travelList'];
      return data.map((e) => Trip.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load trips');
    }
  }

  @override
  Future<void> addTrip(Trip trip) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/travels'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'title': trip.title,
        'startDate': trip.startDate.toIso8601String().split('T')[0],
        'endDate': trip.endDate.toIso8601String().split('T')[0],
        'destination': trip.destination,
        'personCount': trip.personCount,
        'braveLevel': trip.braveLevel,
        'missionFrequency': trip.missionFrequency,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add trip');
    }
  }

  @override
  Future<void> updateTrip(Trip trip) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/travels/${trip.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'title': trip.title,
        'startDate': trip.startDate.toIso8601String().split('T')[0],
        'endDate': trip.endDate.toIso8601String().split('T')[0],
        'destination': trip.destination,
        'personCount': trip.personCount,
        'braveLevel': trip.braveLevel,
        'missionFrequency': trip.missionFrequency,
      }),
    );
    print('PUT /api/travels/${trip.id} status: ${response.statusCode}');
    print('Response body: ${response.body}');
    if (response.statusCode != 200) {
      throw Exception('Failed to update trip');
    }
  }

  @override
  Future<void> deleteTrip(int tripId) async {
    final response = await _client.delete(Uri.parse('$baseUrl/api/travels/${tripId.toString()}'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete trip');
    }
  }

  @override
  Future<void> proposeAiMission({
    required String travelId,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    final url = Uri.parse('$baseUrl/api/travels/$travelId/propose-ai-mission');
    final body = {
      'latitude': latitude,
      'longitude': longitude,
    };
    if (accuracy != null) {
      body['accuracy'] = accuracy;
    }
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (response.statusCode != 202) {
      throw Exception('Failed to propose AI mission: ${response.body}');
    }
  }
} 