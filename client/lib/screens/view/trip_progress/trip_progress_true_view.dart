import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/trip_progress_true_view_model.dart';
import './widget/mission_card.dart';
import '../../../data/models/trip.dart';
import '../../view/edit_trip/edit_trip_view.dart';
import '../../../core/service/location_service.dart';
import 'dart:async';

class TripProgressTrueView extends StatelessWidget {
  final Trip trip;
  final String? proposalId;
  final String? missionTitle;
  final String? missionContent;
  const TripProgressTrueView({super.key, required this.trip, this.proposalId, this.missionTitle, this.missionContent});

  final double cardHeight = 300;

  double get maxOffset => cardHeight / 2;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TripProgressTrueViewModel(
        trip: trip,
        proposalId: proposalId,
        missionTitle: missionTitle,
        missionContent: missionContent,
      ),
      child: _TripProgressTrueViewBody(cardHeight: cardHeight),
    );
  }
}

class _TripProgressTrueViewBody extends StatefulWidget {
  final double cardHeight;
  const _TripProgressTrueViewBody({required this.cardHeight});

  @override
  State<_TripProgressTrueViewBody> createState() => _TripProgressTrueViewBodyState();
}

class _TripProgressTrueViewBodyState extends State<_TripProgressTrueViewBody> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late TripProgressTrueViewModel _model;

  double get maxOffset => widget.cardHeight / 2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller)
      ..addListener(() {
        _model.setDragOffset(_animation.value, maxOffset);
      });
    _model = context.read<TripProgressTrueViewModel>();
    _model.init(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = context.read<TripProgressTrueViewModel>();
    viewModel.fetchMissions();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    _model.onVerticalDragUpdate(details.delta.dy, maxOffset);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _model.onVerticalDragEnd(
      maxOffset,
      _controller,
      () {}, // onTransitionEnd 콜백 (필요시 구현)
      () {}, // onBackEnd 콜백 (필요시 구현)
    );
  }

  Widget _buildGrayCard({required bool isDark, required bool isTop}) {
    return Card(
      elevation: 2,
      color: isDark ? Colors.grey[500] : Colors.grey[300],
      shape: RoundedRectangleBorder(
        borderRadius: isTop
          ? const BorderRadius.vertical(top: Radius.circular(20))
          : const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: const SizedBox(
        width: 340,
        height: 64,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TripProgressTrueViewModel>(
      builder: (context, model, _) {
        final mission = model.missions.isNotEmpty ? model.missions[model.currentMission] : null;
        double rotationX = (model.dragOffset / maxOffset) * 0.7;
        if (model.uploadStatus == UploadStatus.success || model.uploadStatus == UploadStatus.fail) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(model.uploadMessage ?? '')),
            );
            model.resetUploadStatus();
          });
        }
        return GestureDetector(
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                model.tripTitle,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF56BC6C),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                model.tripDate,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFFB8B741),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditTripView(trip: model.trip),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF56BC6C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(fontSize: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Color(0xFFB8B741), width: 2),
                            ),
                            elevation: 2,
                            shadowColor: const Color(0xFFB8B741),
                          ),
                          child: const Text('Edit travel information', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        height: 300,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            // 위쪽(다음 미션) 카드들 (최대 2장)
                            if (model.currentMission < model.missionCount - 2)
                              Positioned(
                                top: -48,
                                child: _buildGrayCard(isDark: true, isTop: true),
                              ),
                            if (model.currentMission < model.missionCount - 1)
                              Positioned(
                                top: -24,
                                child: _buildGrayCard(isDark: false, isTop: true),
                              ),
                            // 아래쪽(이전 미션) 카드들 (최대 2장)
                            if (model.currentMission > 1)
                              Positioned(
                                bottom: -48,
                                child: _buildGrayCard(isDark: true, isTop: false),
                              ),
                            if (model.currentMission > 0)
                              Positioned(
                                bottom: -24,
                                child: _buildGrayCard(isDark: false, isTop: false),
                              ),
                            // 메인 카드 (기존 MissionCard)
                            if (mission != null)
                              Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..translate(0.0, model.dragOffset)
                                  ..rotateX(rotationX),
                                child: MissionCard(
                                  key: ValueKey(model.currentMission),
                                  title: mission.title,
                                  description: mission.content,
                                  isImageRegistered: model.isMissionImageRegistered(model.currentMission),
                                  isCompleted: mission.isCompleted,
                                  imageUrl: model.missionImageUrls[model.currentMission],
                                  onComplete: () {
                                    model.completeMissionAndSet(mission.id, context);
                                  },
                                  onImageRegister: (image) {
                                    model.uploadMissionImageAndSet(model.currentMission, mission.id, image, context);
                                  },
                                  onImageUpdate: (image) {
                                    model.updateMissionImageAndSet(model.currentMission, mission.id, image, context);
                                  },
                                  isProposed: mission.id == -1,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Center(
                      child: Text(
                        model.missionCount > 0
                            ? '${model.currentMission + 1} / ${model.missionCount}'
                            : 'No missions',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          final locationService = LocationService();
                          // 1. 로딩 모달 띄우기
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(child: CircularProgressIndicator()),
                          );
                          // 2. 미션 요청 및 결과 대기
                          await model.getAIMissionWithCurrentLocation(locationService);
                          // 3. 로딩 모달 닫기
                          Navigator.of(context, rootNavigator: true).pop();
                          // 4. 결과 모달 띄우기 (성공 시 미션 정보, 실패 시 에러 메시지)
                          final lastMsg = model.uploadMessage ?? '';
                          final isSuccess = model.uploadStatus == UploadStatus.success;
                          String? title;
                          String? content;
                          if (isSuccess && model.missions.isNotEmpty) {
                            // 새로 추가된 미션이 가장 위(0번)에 있다고 가정
                            final newMission = model.missions.first;
                            title = newMission.title;
                            content = newMission.content;
                          }
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                isSuccess ? 'New mission created!' : 'Mission creation failed',
                                style: const TextStyle(
                                  color: Color(0xFF757575),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: isSuccess
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Title: ${title ?? ''}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF757575),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          content ?? '',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      lastMsg,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text(
                                    'Confirm',
                                    style: TextStyle(
                                      color: Color(0xFF757575),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF757575),
                          side: const BorderSide(color: Color(0xFFDADCE0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Get a new mission'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}