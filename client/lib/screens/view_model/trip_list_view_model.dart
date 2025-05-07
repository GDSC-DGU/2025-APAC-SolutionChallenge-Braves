import 'package:flutter/material.dart';
import '../../data/models/trip.dart';
import '../../data/repository/trip_repository.dart';
import '../../core/provider/trip_provider.dart';

/// [TripListViewModel] - TripListView에서 사용
class TripListViewModel extends ChangeNotifier {
  final TripRepository repository;
  final TripProvider tripProvider;

  TripListViewModel({required this.repository, required this.tripProvider});

  // ──────────────────────────────
  // 1. 상태 변수 (State Variables)
  // ──────────────────────────────
  final List<Map<String, String>> _trips = [
    {
      'title': '제주도 힐링 여행',
      'missionCount': '8/10',
      'date': '2024.03.15 - 2024.03.18',
    },
    {
      'title': '도쿄 맛집 탐방',
      'missionCount': '5/12',
      'date': '2024.02.20 - 2024.02.25',
    },
  ];
  List<Map<String, String>> get trips => List.unmodifiable(_trips);

  // ──────────────────────────────
  // 2. 생성자 (Constructor)
  // ──────────────────────────────
  // TripListViewModel();

  // ──────────────────────────────
  // 3. 상태 변경 메서드 (State Mutators)
  // ──────────────────────────────
  // void addTrip(Map<String, String> trip) { ... notifyListeners(); }

  // ──────────────────────────────
  // 4. 비즈니스 로직/비동기 처리 (Business Logic/Async)
  // ──────────────────────────────
  Future<void> fetchTrips() async {
    final trips = await repository.fetchTrips();
    tripProvider.setTrips(trips);
    notifyListeners();
  }

  // ──────────────────────────────
  // 5. 기타 유틸리티/초기화/정리 (Utility/Dispose)
  // ──────────────────────────────
  // void clear() { ... }
} 