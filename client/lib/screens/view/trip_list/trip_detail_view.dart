import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/trip_detail_view_model.dart';
import '../../common/mission_card.dart';
import '../../../data/repository/mission_repository.dart';

class TripDetailView extends StatelessWidget {
  final String title;
  final String date;
  final String missionCount;
  final int travelId;
  final String destination;

  const TripDetailView({
    super.key,
    required this.title,
    required this.date,
    required this.missionCount,
    required this.travelId,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
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
              title: Text(model.title, style: const TextStyle(color: Color(0xFF56BC6C))),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF56BC6C),
              elevation: 0,
            ),
            backgroundColor: Colors.white,
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trip Info',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF56BC6C),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, size: 20, color: Color(0xFF757575)),
                              const SizedBox(width: 8),
                              Text(
                                model.date,
                                style: const TextStyle(fontSize: 16, color: Color(0xFF757575)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.place, size: 20, color: Color(0xFF757575)),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  destination,
                                  style: const TextStyle(fontSize: 16, color: Color(0xFF757575)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.check_circle_outline, size: 20, color: Color(0xFF757575)),
                              const SizedBox(width: 8),
                              Text(
                                'Completed Missions: ${model.missionCount}',
                                style: const TextStyle(fontSize: 16, color: Color(0xFF757575)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Mission List',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF757575),
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
                          image: mission.completionImage != null ? NetworkImage(mission.completionImage!) : null,
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
    );
  }
} 