import 'package:flutter/material.dart';
import '../../../config/color_system.dart';
import '../../common/trip_card.dart';
import '../../common/new_trip_button.dart';
import '../add_trip/add_trip_view.dart';

class TripListView extends StatelessWidget {
  const TripListView({super.key});

  @override
  Widget build(BuildContext context) {
    // 임시 데이터
    final trips = [
      {
        'title': '제주도 힐링 여행',
        'missionCount': '8/10',
        'date': '2024.03.15 - 2024.03.18',
      },
      {
        'title': '도쿄 맛집 탐방',
        'missionCount': '5/12',
        'date': '2024.02.20 - 2024.02.25',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          NewTripButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTripView()),
              );
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return TripCard(
                  title: trip['title']!,
                  missionCount: trip['missionCount']!,
                  date: trip['date']!,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 