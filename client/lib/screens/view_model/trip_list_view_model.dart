import 'package:flutter/material.dart';
import '../../data/repository/trip_repository.dart';
import '../../core/provider/trip_provider.dart';
import 'package:provider/provider.dart';
import '../../data/models/trip.dart';

/// [TripListViewModel] - TripListView에서 사용
class TripListViewModel extends ChangeNotifier {
  late final TripRepository repository;
  late final TripProvider tripProvider;

  TripListViewModel();

  Trip? _ongoingTrip;
  Trip? get ongoingTrip => _ongoingTrip;

  void updateOngoingTrip() {
    final now = DateTime.now();
    final found = tripProvider.trips.where(
      (trip) => !now.isBefore(trip.startDate) && !now.isAfter(trip.endDate),
    );
    _ongoingTrip = found.isNotEmpty ? found.first : null;
    notifyListeners();
  }

  void init(BuildContext context) {
    repository = Provider.of<TripRepository>(context, listen: false);
    tripProvider = Provider.of<TripProvider>(context, listen: false);
  }

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
    assert(repository != null, 'repository must be initialized by calling init(context)');
    final trips = await repository.fetchTrips();
    tripProvider.setTrips(trips);
    updateOngoingTrip();
    notifyListeners();
  }

  // 여행 삭제
  Future<void> deleteTrip(int tripId) async {
    await repository.deleteTrip(tripId);
    await fetchTrips(); // 삭제 후 리스트 갱신
    notifyListeners();
  }

  // ──────────────────────────────
  // 5. 기타 유틸리티/초기화/정리 (Utility/Dispose)
  // ──────────────────────────────
  // void clear() { ... }

  // 진행중이 아닌 여행만 반환
  List<Trip> get filteredTrips =>
      tripProvider.trips.where((trip) => trip != _ongoingTrip).toList();

  bool get hasOngoingTrip => _ongoingTrip != null;
} 