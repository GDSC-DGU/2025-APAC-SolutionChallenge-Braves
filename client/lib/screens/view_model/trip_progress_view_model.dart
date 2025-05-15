import 'package:flutter/material.dart';
import '../../core/provider/trip_provider.dart';
import '../../data/models/trip.dart';
import '../../core/service/background_location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [TripProgressViewModel] - TripProgressView에서 사용
class TripProgressViewModel extends ChangeNotifier {
  // ──────────────────────────────
  // 1. 상태 변수 (State Variables)
  // ──────────────────────────────
  Trip? _ongoingTrip;
  Trip? get ongoingTrip => _ongoingTrip;

  // ──────────────────────────────
  // 2. 생성자 (Constructor)
  // ──────────────────────────────
  TripProgressViewModel({required TripProvider tripProvider}) {
    updateOngoingTrip(tripProvider);
  }

  void updateOngoingTrip(TripProvider tripProvider) async {
    Trip? prevOngoing = _ongoingTrip;
    _findOngoingTrip(tripProvider.trips);
    
    // 여행 시작/종료 상태 변화 감지
    if (prevOngoing == null && _ongoingTrip != null) {
      // 여행 시작됨
      if (tripProvider.trips.isNotEmpty) {  // 여행이 있는 경우에만 위치 서비스 시작
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('travelId', _ongoingTrip!.id.toString());
        // missionFrequency(1~10)에 따라 interval 계산 (10: 6분, 1: 60분)
        final freq = _ongoingTrip!.missionFrequency;
        final minutes = 66 - 6 * freq; // 10→6분, 1→60분
        final interval = Duration(minutes: minutes.clamp(6, 60));
        BackgroundLocationService.startLocationService(interval: interval);
      }
    } else if (prevOngoing != null && _ongoingTrip == null) {
      // 여행 종료됨
      BackgroundLocationService.stopLocationService();
    }
  }

  // ──────────────────────────────
  // 3. 상태 변경 메서드 (State Mutators)
  // ──────────────────────────────
  void toggleTripStatus() {
    bool wasOngoing = _ongoingTrip != null;
    _ongoingTrip = null;
    notifyListeners();
    if (wasOngoing) {
      BackgroundLocationService.stopLocationService();
    }
  }

  // ──────────────────────────────
  // 4. 비즈니스 로직/비동기 처리 (Business Logic/Async)
  // ──────────────────────────────
  // Future<void> fetchTripStatus() async { ... }

  // ──────────────────────────────
  // 5. 기타 유틸리티/초기화/정리 (Utility/Dispose)
  // ──────────────────────────────
  // void clear() { ... }

  void _findOngoingTrip(List<Trip> trips) {
    final now = DateTime.now();
    final found = trips.where(
      (trip) => !now.isBefore(trip.startDate) && !now.isAfter(trip.endDate),
    );
    _ongoingTrip = found.isNotEmpty ? found.first : null;
    notifyListeners();
  }

  bool get hasOngoingTrip => _ongoingTrip != null;
} 