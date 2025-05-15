import 'package:flutter/material.dart';
import '../../../config/font_system.dart';
import '../../common/new_trip_button.dart';
import '../add_trip/add_trip_view.dart';
import '../../view_model/add_trip_view_model.dart';
import '../../../data/repository/trip_repository.dart';
import '../../../core/provider/trip_provider.dart';
import 'package:provider/provider.dart';

class TripProgressFalseView extends StatelessWidget {
  const TripProgressFalseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Placeholder for the gray box (can be replaced with an actual image or Container)
        Container(
          height: 400,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Image.asset(
              'assets/images/new_trip_start.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Text indicating no ongoing trip
        Text(
          'No ongoing trip!',
          style: AppFonts.body1.copyWith(
            color: const Color(0xFF56BC6C),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Subtext
        Text(
          'Start a new trip and create unforgettable memories.',
          textAlign: TextAlign.center,
          style: AppFonts.body2.copyWith(
            color: const Color(0xFFB8B741),
          ),
        ),
        const SizedBox(height: 24),
        // New Trip Button
        NewTripButton(
          onPressed: () {
            final addTripViewModel = AddTripViewModel(
              repository: context.read<TripRepository>(),
              tripProvider: context.read<TripProvider>(),
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddTripView(viewModel: addTripViewModel),
              ),
            );
          },
        ),
      ],
    );
  }
}