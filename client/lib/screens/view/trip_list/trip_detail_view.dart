import 'package:flutter/material.dart';
import '../../../config/color_system.dart';
import '../../../config/font_system.dart';
import '../../common/mission_card.dart';

class TripDetailView extends StatelessWidget {
  final String title;
  final String date;
  final String missionCount;

  const TripDetailView({
    super.key,
    required this.title,
    required this.date,
    required this.missionCount,
  });

  @override
  Widget build(BuildContext context) {
    // 임시 미션 데이터
    final missions = [
      {
        'title': '성산일출봉에서 일출 보기',
        'date': '2024.03.16',
        'image': 'assets/images/test_mission.jpg',
      },
      {
        'title': '우도 자전거 일주',
        'date': '2024.03.17',
        'image': null,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '여행 정보',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          date,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '완료한 미션: $missionCount',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '완료한 미션',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: missions.length,
                itemBuilder: (context, index) {
                  final mission = missions[index];
                  return MissionCard(
                    title: mission['title']!,
                    date: mission['date']!,
                    image: mission['image'] != null ? AssetImage(mission['image']!) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 