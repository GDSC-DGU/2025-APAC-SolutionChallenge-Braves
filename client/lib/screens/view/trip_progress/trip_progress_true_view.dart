import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/trip_progress_true_view_model.dart';
import './widget/mission_card.dart';

class TripProgressTrueView extends StatelessWidget {
  const TripProgressTrueView({super.key});

  final double cardHeight = 300;

  double get maxOffset => cardHeight / 2;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TripProgressTrueViewModel(),
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

  TripProgressTrueViewModel get model => Provider.of<TripProgressTrueViewModel>(context, listen: false);

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
        model.setDragOffset(_animation.value, maxOffset);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (model.isAnimating) return;
    model.setDragOffset(model.dragOffset + details.delta.dy, maxOffset);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (model.isAnimating) return;
    double threshold = maxOffset * 0.7;
    if (model.dragOffset.abs() > threshold) {
      int direction = model.dragOffset > 0 ? 1 : -1;
      int newIndex = model.currentMission + direction;
      if (newIndex >= 0 && newIndex < model.missionCount) {
        model.setAnimating(true);
        _animation = Tween<double>(
          begin: model.dragOffset,
          end: direction * maxOffset,
        ).animate(_controller);
        _controller.forward(from: 0).then((_) {
          model.setCurrentMission(newIndex);
          model.resetDragOffset();
          model.setAnimating(false);
        });
      } else {
        _animateBack();
      }
    } else {
      _animateBack();
    }
  }

  void _animateBack() {
    model.setAnimating(true);
    _animation = Tween<double>(begin: model.dragOffset, end: 0).animate(_controller);
    _controller.forward(from: 0).then((_) {
      model.resetDragOffset();
      model.setAnimating(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TripProgressTrueViewModel>(
      builder: (context, model, _) {
        final mission = model.missions[model.currentMission];
        double rotationX = (model.dragOffset / maxOffset) * 0.7;
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(model.tripTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(model.tripDate, style: const TextStyle(fontSize: 15, color: Colors.black54)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        height: widget.cardHeight,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (model.currentMission > 0)
                              Positioned(
                                bottom: 0,
                                child: Opacity(
                                  opacity: 0.5,
                                  child: Transform.scale(
                                    scale: 0.8,
                                    child: Card(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      color: Colors.grey[300],
                                      child: const SizedBox(
                                        width: 240,
                                        height: 120,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (model.currentMission < model.missionCount - 1)
                              Positioned(
                                top: 0,
                                child: Opacity(
                                  opacity: 0.5,
                                  child: Transform.scale(
                                    scale: 0.8,
                                    child: Card(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      color: Colors.grey[300],
                                      child: const SizedBox(
                                        width: 240,
                                        height: 120,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..translate(0.0, model.dragOffset)
                                ..rotateX(rotationX),
                              child: MissionCard(
                                key: ValueKey(model.currentMission),
                                title: mission['title']!,
                                description: mission['description']!,
                                onComplete: () {},
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
                        '${model.currentMission + 1} / ${model.missionCount}',
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          // 새로운 미션 받기 로직
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Color(0xFFDDDDDD)),
                        ),
                        child: const Text('새로운 미션 받기'),
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