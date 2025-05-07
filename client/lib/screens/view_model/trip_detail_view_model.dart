import 'package:flutter/material.dart';
import '../../data/models/mission.dart';
import '../../data/repository/mission_repository.dart';

/// [TripDetailViewModel] - TripDetailView에서 사용
class TripDetailViewModel extends ChangeNotifier {
  // ──────────────────────────────
  // 1. 상태 변수 (State Variables)
  // ──────────────────────────────
  final String title;
  final String date;
  final String missionCount;
  final int travelId;
  final MissionRepository repository;

  List<Mission> _missions = [];
  List<Mission> get missions => List.unmodifiable(_missions);

  // ──────────────────────────────
  // 2. 생성자 (Constructor)
  // ──────────────────────────────
  TripDetailViewModel({
    required this.title,
    required this.date,
    required this.missionCount,
    required this.travelId,
    required this.repository,
  }) {
    fetchMissions();
  }

  // ──────────────────────────────
  // 3. 상태 변경 메서드 (State Mutators)
  // ──────────────────────────────
  // void addMission(Map<String, dynamic> mission) { ... notifyListeners(); }

  // ──────────────────────────────
  // 4. 비즈니스 로직/비동기 처리 (Business Logic/Async)
  // ──────────────────────────────
  Future<void> fetchMissions() async {
    _missions = await repository.fetchMissions(travelId);
    notifyListeners();
  }

  // ──────────────────────────────
  // 5. 기타 유틸리티/초기화/정리 (Utility/Dispose)
  // ──────────────────────────────
  // void clear() { ... }
} 