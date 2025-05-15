import '../models/trip.dart';
import 'trip_repository.dart';
import '../datasource/trip_datasource.dart';

class TripRepositoryImpl implements TripRepository {
  final TripDataSource dataSource;
  TripRepositoryImpl(this.dataSource);

  @override
  Future<List<Trip>> fetchTrips() async {
    return await dataSource.fetchTrips();
  }

  @override
  Future<void> addTrip(Trip trip) async {
    await dataSource.addTrip(trip);
  }

  @override
  Future<void> updateTrip(Trip trip) async {
    await dataSource.updateTrip(trip);
  }

  @override
  Future<void> deleteTrip(int tripId) async {
    await dataSource.deleteTrip(tripId);
  }

  @override
  Future<void> proposeAiMission({
    required String travelId,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    await dataSource.proposeAiMission(
      travelId: travelId,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
    );
  }
} 