import 'package:flutter/material.dart';

/// [TripProgressTrueViewModel] - TripProgressTrueView에서 사용
class TripProgressTrueViewModel extends ChangeNotifier {
  // ──────────────────────────────
  // 1. 상태 변수 (State Variables)
  // ──────────────────────────────
  final String tripTitle = '제주도 힐링 여행';
  final String tripDate = '2024.03.15 - 2024.03.18';
  final List<Map<String, String>> missions = [
    {
      'title': '성산일출봉에서 일출 보기',
      'description': '제주도의 상징적인 일출 명소인 성산일출봉에서 아름다운 일출을 감상하고 인증샷을 찍어보세요.',
    },
    {
      'title': '우도 자전거 일주',
      'description': '우도를 자전거로 일주하며 아름다운 풍경을 즐기세요.',
    },
    // ... 추가 미션
  ];
  int _currentMission = 0;
  double _dragOffset = 0.0;
  bool _isAnimating = false;
  int get currentMission => _currentMission;
  double get dragOffset => _dragOffset;
  bool get isAnimating => _isAnimating;
  int get missionCount => missions.length;

  // ──────────────────────────────
  // 2. 생성자 (Constructor)
  // ──────────────────────────────
  // TripProgressTrueViewModel();

  // ──────────────────────────────
  // 3. 상태 변경 메서드 (State Mutators)
  // ──────────────────────────────
  void setDragOffset(double value, double maxOffset) {
    _dragOffset = value.clamp(-maxOffset, maxOffset);
    notifyListeners();
  }
  void setAnimating(bool value) {
    _isAnimating = value;
    notifyListeners();
  }
  void setCurrentMission(int value) {
    _currentMission = value;
    notifyListeners();
  }
  void resetDragOffset() {
    _dragOffset = 0.0;
    notifyListeners();
  }

  // ──────────────────────────────
  // 4. 비즈니스 로직/비동기 처리 (Business Logic/Async)
  // ──────────────────────────────
  // Future<void> fetchMissions() async { ... }

  // ──────────────────────────────
  // 5. 기타 유틸리티/초기화/정리 (Utility/Dispose)
  // ──────────────────────────────
  // void clear() { ... }
} 