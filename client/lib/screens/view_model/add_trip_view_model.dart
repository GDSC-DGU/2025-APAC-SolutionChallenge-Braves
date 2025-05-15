import 'package:flutter/material.dart';
import '../../data/models/trip.dart';
import '../../data/repository/trip_repository.dart';
import '../../core/provider/trip_provider.dart';

/// [AddTripViewModel] - AddTripView에서 사용
class AddTripViewModel extends ChangeNotifier {
  final TripRepository repository;
  final TripProvider tripProvider;

  AddTripViewModel({required this.repository, required this.tripProvider});

  // ──────────────────────────────
  // 1. 상태 변수 (State Variables)
  // ──────────────────────────────
  final TextEditingController titleController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  int? _people;
  double _brave = 0.5;
  double _density = 0.5;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  int? get people => _people;
  double get brave => _brave;
  double get density => _density;

  // ──────────────────────────────
  // 2. 생성자 (Constructor)
  // ──────────────────────────────
  // AddTripViewModel();

  // ──────────────────────────────
  // 3. 상태 변경 메서드 (State Mutators)
  // ──────────────────────────────
  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }
  void setPeople(int? value) {
    _people = value;
    notifyListeners();
  }
  void setBrave(double value) {
    _brave = value;
    notifyListeners();
  }
  void setDensity(double value) {
    _density = value;
    notifyListeners();
  }

  // ──────────────────────────────
  // 4. 비즈니스 로직/비동기 처리 (Business Logic/Async)
  // ──────────────────────────────
  Future<void> saveTrip() async {
    // 임시 userId, id는 0으로 지정 (실제 앱에서는 로그인 유저 정보 활용)
    final trip = Trip(
      id: 0,
      userId: 0,
      title: titleController.text,
      startDate: _startDate!,
      endDate: _endDate!,
      destination: destinationController.text,
      personCount: _people ?? 1,
      braveLevel: (_brave * 10).toInt(),
      missionFrequency: (_density * 10).toInt(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      totalMissions: 0,
      completedMissions: 0,
    );
    await repository.addTrip(trip);
    tripProvider.addTrip(trip);
  }

  // ──────────────────────────────
  // 5. 기타 유틸리티/초기화/정리 (Utility/Dispose)
  // ──────────────────────────────
  void clear() {
    titleController.clear();
    destinationController.clear();
    _startDate = null;
    _endDate = null;
    _people = null;
    _brave = 0.5;
    _density = 0.5;
    notifyListeners();
  }
} 