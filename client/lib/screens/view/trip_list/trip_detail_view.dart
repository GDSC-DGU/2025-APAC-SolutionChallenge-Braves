import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/trip_detail_view_model.dart';
import '../../../config/color_system.dart';
import '../../../config/font_system.dart';
import '../../common/mission_card.dart';
import '../../../data/repository/mission_repository.dart';
import '../../../data/datasource/mission_datasource.dart';
import '../../../core/provider/user_provider.dart';

class TripDetailView extends StatelessWidget {
  final String title;
  final String date;
  final String missionCount;
  final int travelId;

  const TripDetailView({
    super.key,
    required this.title,
    required this.date,
    required this.missionCount,
    required this.travelId,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MissionRepository>(
          create: (context) => MissionRepositoryImpl(
            MissionDataSourceImpl(context.read<UserProvider>()),
          ),
        ),
      ],
      child: ChangeNotifierProvider(
        create: (context) => TripDetailViewModel(
          title: title,
          date: date,
          missionCount: missionCount,
          travelId: travelId,
          repository: context.read<MissionRepository>(),
        ),
        child: Consumer<TripDetailViewModel>(
          builder: (context, model, _) {
            return Scaffold(
              appBar: AppBar(
                title: Text(model.title),
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
                                  model.date,
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
                                  '완료한 미션: ${model.missionCount}',
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
                      '미션 목록',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: model.missions.length,
                        itemBuilder: (context, index) {
                          final mission = model.missions[index];
                          return MissionCard(
                            title: mission.title,
                            date: mission.createdAt != null ? mission.createdAt!.toString().split(' ')[0] : '',
                            image: null, // completionImage 연동 필요시 수정
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 