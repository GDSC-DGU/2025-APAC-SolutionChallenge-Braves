import 'package:flutter/material.dart';
import '../../../config/color_system.dart';
import '../../../config/font_system.dart';
import '../../common/new_trip_button.dart';
import '../add_trip/add_trip_view.dart';

class TripProgressFalseView extends StatelessWidget {
  const TripProgressFalseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Placeholder for the gray box (can be replaced with an actual image or Container)
        Container(
          height: 200,
          width: double.infinity,
          color: Colors.grey,
        ),
        const SizedBox(height: 16),
        // Text indicating no ongoing trip
        Text(
          '아직 진행중인 여행이 없어요!',
          style: AppFonts.body1,
        ),
        const SizedBox(height: 8),
        // Subtext
        Text(
          '새로운 여행을 시작하고\n잊지 못할 추억을 만들어보세요.',
          textAlign: TextAlign.center,
          style: AppFonts.body2,
        ),
        const SizedBox(height: 24),
        // New Trip Button
        NewTripButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTripView()),
              );
          },
        ),
      ],
    );
  }
}