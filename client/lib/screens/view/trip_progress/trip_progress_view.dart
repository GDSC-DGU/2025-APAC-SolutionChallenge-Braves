import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/trip_progress_view_model.dart';
import '../../../config/color_system.dart';
import './trip_progress_true_view.dart';
import './trip_progress_false_view.dart';

class TripProgressView extends StatelessWidget {
  const TripProgressView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TripProgressViewModel(),
      child: Consumer<TripProgressViewModel>(
        builder: (context, model, _) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Column(
              children: [
                ElevatedButton(
                  onPressed: model.toggleTripStatus,
                  child: Text(model.hasOngoingTrip ? '여행 종료하기' : '여행 시작하기'),
                ),
                Expanded(
                  child: model.hasOngoingTrip
                      ? TripProgressTrueView()
                      : const TripProgressFalseView(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 