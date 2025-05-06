import 'package:flutter/material.dart';

/// [ProfileViewModel] - ProfileView에서 사용
class ProfileViewModel extends ChangeNotifier {
  // ──────────────────────────────
  // 1. 상태 변수 (State Variables)
  // ──────────────────────────────
  final String profileImage = 'https://i.pravatar.cc/300';
  final String username = '홍길동';
  final String email = 'honggildong@example.com';
  final String role = 'user';
  final DateTime createdAt = DateTime(2023, 5, 1, 10, 30);

  // ──────────────────────────────
  // 2. 생성자 (Constructor)
  // ──────────────────────────────
  // ProfileViewModel();

  // ──────────────────────────────
  // 3. 상태 변경 메서드 (State Mutators)
  // ──────────────────────────────
  // void setProfile(...) { ... notifyListeners(); }

  // ──────────────────────────────
  // 4. 비즈니스 로직/비동기 처리 (Business Logic/Async)
  // ──────────────────────────────
  // Future<void> fetchProfile() async { ... }

  // ──────────────────────────────
  // 5. 기타 유틸리티/초기화/정리 (Utility/Dispose)
  // ──────────────────────────────
  // void clear() { ... }
} 