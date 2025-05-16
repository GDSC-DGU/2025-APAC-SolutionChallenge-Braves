import 'package:flutter/material.dart';
import '../../data/models/trip.dart';
import '../../data/models/mission.dart';
import '../../data/repository/mission_repository.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/service/location_service.dart';

enum UploadStatus { idle, success, fail }
enum CompleteStatus { idle, success, fail }

/// [TripProgressTrueViewModel] - TripProgressTrueView에서 사용
class TripProgressTrueViewModel extends ChangeNotifier {
  final Trip trip;
  final String? proposalId;
  final String? missionTitle;
  final String? missionContent;
  late final MissionRepository repository;

  TripProgressTrueViewModel({required this.trip, this.proposalId, this.missionTitle, this.missionContent});

  void init(BuildContext context) {
    repository = Provider.of<MissionRepository>(context, listen: false);
    fetchMissions();
  }

  String get tripTitle => trip.title;
  String get tripDate => '${trip.startDate.toString().split(' ')[0]} - ${trip.endDate.toString().split(' ')[0]}';

  List<Mission> _missions = [];
  List<Mission> get missions => _missions;

  int _currentMission = 0;
  double _dragOffset = 0.0;
  bool _isAnimating = false;
  int get currentMission => _currentMission;
  double get dragOffset => _dragOffset;
  bool get isAnimating => _isAnimating;
  int get missionCount => _missions.length;

  List<XFile?> _missionImages = [];
  List<XFile?> get missionImages => _missionImages;

  List<String?> _missionImageUrls = [];
  List<String?> get missionImageUrls => _missionImageUrls;

  bool isMissionImageRegistered(int index) {
    if (index < 0 || index >= _missionImageUrls.length) return false;
    return _missionImageUrls[index] != null && _missionImageUrls[index]!.isNotEmpty;
  }

  void setMissionImage(int index, XFile image) {
    if (index >= 0 && index < _missionImages.length) {
      _missionImages[index] = image;
      notifyListeners();
    }
  }

  void setMissionImageUrl(int index, String url) {
    if (index >= 0 && index < _missionImageUrls.length) {
      _missionImageUrls[index] = url;
      notifyListeners();
    }
  }

  UploadStatus _uploadStatus = UploadStatus.idle;
  String? _uploadMessage;

  UploadStatus get uploadStatus => _uploadStatus;
  String? get uploadMessage => _uploadMessage;

  void resetUploadStatus() {
    _uploadStatus = UploadStatus.idle;
    _uploadMessage = null;
  }

  CompleteStatus _completeStatus = CompleteStatus.idle;
  String? _completeMessage;

  CompleteStatus get completeStatus => _completeStatus;
  String? get completeMessage => _completeMessage;

  void resetCompleteStatus() {
    _completeStatus = CompleteStatus.idle;
    _completeMessage = null;
  }

  Future<void> uploadMissionImageAndSet(int index, int missionId, XFile image, BuildContext context) async {
    resetUploadStatus();
    final result = await uploadMissionImage(missionId, image, context);
    if (result != null && result['success'] == true) {
      await fetchMissions(); // 업로드 성공 시 미션 리스트를 서버에서 다시 받아옴
      _uploadStatus = UploadStatus.success;
      _uploadMessage = '이미지 업로드 성공!';
    } else {
      _uploadStatus = UploadStatus.fail;
      _uploadMessage = '이미지 업로드 실패';
    }
    notifyListeners();
  }

  Future<void> updateMissionImageAndSet(int index, int missionId, XFile image, BuildContext context) async {
    resetUploadStatus();
    final result = await updateMissionImage(missionId, image, context);
    if (result != null && result['success'] == true) {
      await fetchMissions(); // 수정 성공 시 미션 리스트를 서버에서 다시 받아옴
      _uploadStatus = UploadStatus.success;
      _uploadMessage = '이미지 수정 성공!';
    } else {
      _uploadStatus = UploadStatus.fail;
      _uploadMessage = '이미지 수정 실패';
    }
    notifyListeners();
  }

  Future<void> completeMissionAndSet(int missionId, BuildContext context) async {
    resetCompleteStatus();
    try {
      final result = await repository.completeMission(missionId, context);
      if (result['success'] == true) {
        _completeStatus = CompleteStatus.success;
        _completeMessage = result['msg'] ?? '미션 완료!';
        // 미션 상태 갱신
        final idx = _missions.indexWhere((m) => m.id == missionId);
        if (idx != -1) {
          _missions[idx] = Mission(
            id: _missions[idx].id,
            travelId: _missions[idx].travelId,
            title: _missions[idx].title,
            content: _missions[idx].content,
            isCompleted: true,
            createdAt: _missions[idx].createdAt,
            updatedAt: _missions[idx].updatedAt,
          );
          // 다시 정렬
          _missions.sort((a, b) {
            if (a.isCompleted == b.isCompleted) return 0;
            return a.isCompleted ? 1 : -1;
          });
        }
      } else {
        _completeStatus = CompleteStatus.fail;
        _completeMessage = result['msg'] ?? '미션 완료 실패';
      }
    } catch (e) {
      _completeStatus = CompleteStatus.fail;
      _completeMessage = '미션 완료 실패: $e';
    }
    notifyListeners();
  }

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
  Future<void> fetchMissions() async {
    _missions = await repository.fetchMissions(trip.id);
    // 완료되지 않은 미션이 먼저, 완료된 미션이 나중에 오도록 정렬 + 최신 생성순으로 정렬
    _missions.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      // createdAt이 null일 경우 오래된 것으로 간주
      final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime); // 최신순(내림차순)
    });
    // FCM으로 전달된 미션이 있으면 임시로 추가
    if (missionTitle != null && missionContent != null) {
      _missions.insert(0, Mission(
        id: -1, // 임시 ID
        travelId: trip.id,
        title: missionTitle!,
        content: missionContent!,
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        completionImage: null,
      ));
      _currentMission = 0; // 새 미션이 추가되면 가장 위로 오도록 인덱스도 0으로
    } else if (_missions.isNotEmpty) {
      // 새 미션이 없으면 기존 로직대로, 현재 미션 인덱스가 범위 밖이면 0으로
      if (_currentMission >= _missions.length || _currentMission < 0) {
        _currentMission = 0;
      }
    }
    // 미션 개수에 맞게 이미지 URL 리스트를 미션의 completionImage로 초기화
    _missionImageUrls = _missions.map((m) => m.completionImage).toList();
    // (선택) _missionImages는 로컬에서만 사용, 서버에서 받아온 이미지는 URL로만 관리
    _missionImages = List<XFile?>.filled(_missions.length, null);
    notifyListeners();
  }

  void completeMissionTransition(int newIndex) {
    setCurrentMission(newIndex);
    resetDragOffset();
    setAnimating(false);
  }

  void cancelMissionTransition() {
    resetDragOffset();
    setAnimating(false);
  }

  Future<Map<String, dynamic>?> uploadMissionImage(int missionId, XFile image, BuildContext context) async {
    try {
      final result = await repository.uploadMissionImage(missionId, image, context);
      return result;
    } catch (e) {
      debugPrint('이미지 업로드 실패: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateMissionImage(int missionId, XFile image, BuildContext context) async {
    try {
      final result = await repository.updateMissionImage(missionId, image, context);
      return result;
    } catch (e) {
      debugPrint('이미지 수정 실패: $e');
      return null;
    }
  }

  void onVerticalDragUpdate(double delta, double maxOffset) {
    if (_isAnimating) return;
    setDragOffset(_dragOffset + delta, maxOffset);
  }

  void onVerticalDragEnd(double maxOffset, AnimationController controller, VoidCallback onTransitionEnd, VoidCallback onBackEnd) {
    if (_isAnimating) return;
    double threshold = maxOffset * 0.7;
    if (_dragOffset.abs() > threshold) {
      int direction = _dragOffset > 0 ? 1 : -1;
      int newIndex = _currentMission + direction;
      if (newIndex >= 0 && newIndex < missionCount) {
        setAnimating(true);
        final animation = Tween<double>(
          begin: _dragOffset,
          end: direction * maxOffset,
        ).animate(controller);
        controller.forward(from: 0).then((_) {
          completeMissionTransition(newIndex);
          onTransitionEnd();
        });
      } else {
        animateBack(controller, onBackEnd);
      }
    } else {
      animateBack(controller, onBackEnd);
    }
  }

  void animateBack(AnimationController controller, VoidCallback onBackEnd) {
    setAnimating(true);
    final animation = Tween<double>(begin: _dragOffset, end: 0).animate(controller);
    controller.forward(from: 0).then((_) {
      cancelMissionTransition();
      onBackEnd();
    });
  }

  Future<void> getAIMissionWithCurrentLocation(LocationService locationService) async {
    try {
      final locationData = await locationService.getCurrentPosition();

      if (locationData == null) {
        // 위치 정보 획득 실패 처리
        _uploadStatus = UploadStatus.fail;
        _uploadMessage = '위치 정보를 가져올 수 없습니다.';
        notifyListeners();
        return;
      }
      final result = await repository.generateDirectAIMission(
        trip.id,
        locationData.latitude!,
        locationData.longitude!,
        accuracy: locationData.accuracy,
      );
      if (result['success'] == true) {
        await fetchMissions(); // 미션 리스트 갱신
        _uploadStatus = UploadStatus.success;
        _uploadMessage = result['msg'] ?? 'AI 미션 생성 성공';
      } else {
        _uploadStatus = UploadStatus.fail;
        _uploadMessage = result['msg'] ?? 'AI 미션 생성 실패';
      }
    } catch (e) {
      _uploadStatus = UploadStatus.fail;
      _uploadMessage = 'AI 미션 생성 실패: $e';
    }
    notifyListeners();
  }

  // ──────────────────────────────
  // 5. 기타 유틸리티/초기화/정리 (Utility/Dispose)
  // ──────────────────────────────
  // void clear() { ... }
} 