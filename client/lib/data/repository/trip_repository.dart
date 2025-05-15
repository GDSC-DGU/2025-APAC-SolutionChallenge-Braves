import '../models/trip.dart';

abstract class TripRepository {
  Future<List<Trip>> fetchTrips();
  Future<void> addTrip(Trip trip);
  Future<void> updateTrip(Trip trip);
  Future<void> deleteTrip(int tripId);
  Future<void> proposeAiMission({
    required String travelId,
    required double latitude,
    required double longitude,
    double? accuracy,
  });
} 