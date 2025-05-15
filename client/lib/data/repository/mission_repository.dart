import '../models/mission.dart';
import '../datasource/mission_datasource.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

abstract class MissionRepository {
  Future<List<Mission>> fetchMissions(int travelId);
  Future<Map<String, dynamic>> uploadMissionImage(int missionId, XFile image, BuildContext context);
  Future<Map<String, dynamic>> updateMissionImage(int missionId, XFile image, BuildContext context);
  Future<Map<String, dynamic>> completeMission(int missionId, BuildContext context);
  Future<Map<String, dynamic>> generateDirectAIMission(int travelId, double latitude, double longitude, {double? accuracy});
  Future<Map<String, dynamic>> acceptMissionProposal(String proposalId);
}

class MissionRepositoryImpl implements MissionRepository {
  final MissionDataSource dataSource;
  MissionRepositoryImpl(this.dataSource);

  @override
  Future<List<Mission>> fetchMissions(int travelId) async {
    return await dataSource.fetchMissions(travelId);
  }

  @override
  Future<Map<String, dynamic>> uploadMissionImage(int missionId, XFile image, BuildContext context) async {
    return await dataSource.uploadMissionImage(missionId, image, context);
  }

  @override
  Future<Map<String, dynamic>> updateMissionImage(int missionId, XFile image, BuildContext context) async {
    return await dataSource.updateMissionImage(missionId, image, context);
  }

  @override
  Future<Map<String, dynamic>> completeMission(int missionId, BuildContext context) async {
    return await dataSource.completeMission(missionId, context);
  }

  @override
  Future<Map<String, dynamic>> generateDirectAIMission(int travelId, double latitude, double longitude, {double? accuracy}) async {
    return await dataSource.generateDirectAIMission(travelId, latitude, longitude, accuracy: accuracy);
  }

  @override
  Future<Map<String, dynamic>> acceptMissionProposal(String proposalId) async {
    return await dataSource.acceptMissionProposal(proposalId);
  }
} 