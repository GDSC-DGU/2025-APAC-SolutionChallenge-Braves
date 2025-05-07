import 'package:flutter/material.dart';

/// [TripProgressViewModel] - TripProgressView에서 사용
class TripProgressViewModel extends ChangeNotifier {
  // ──────────────────────────────
  // 1. 상태 변수 (State Variables)
  // ──────────────────────────────
  bool _hasOngoingTrip = false;
  bool get hasOngoingTrip => _hasOngoingTrip;

  // ──────────────────────────────
  // 2. 생성자 (Constructor)
  // ──────────────────────────────
  // TripProgressViewModel();

  // ──────────────────────────────
  // 3. 상태 변경 메서드 (State Mutators)
  // ──────────────────────────────
  void toggleTripStatus() {
    _hasOngoingTrip = !_hasOngoingTrip;
    notifyListeners();
  }

  // ──────────────────────────────
  // 4. 비즈니스 로직/비동기 처리 (Business Logic/Async)
  // ──────────────────────────────
  // Future<void> fetchTripStatus() async { ... }

  // ──────────────────────────────
  // 5. 기타 유틸리티/초기화/정리 (Utility/Dispose)
  // ──────────────────────────────
  // void clear() { ... }
} 