import 'package:flutter/material.dart';
import '../../data/models/trip.dart';
import '../../data/repository/trip_repository.dart';
import '../../core/provider/trip_provider.dart';

/// [EditTripViewModel] - EditTripView에서 사용
class EditTripViewModel extends ChangeNotifier {
  final TripRepository repository;
  final TripProvider tripProvider;
  final Trip originalTrip;

  EditTripViewModel({
    required this.repository,
    required this.tripProvider,
    required this.originalTrip,
  }) {
    titleController.text = originalTrip.title;
    destinationController.text = originalTrip.destination;
    _startDate = originalTrip.startDate;
    _endDate = originalTrip.endDate;
    _people = originalTrip.personCount;
    _brave = originalTrip.braveLevel / 10.0;
    _density = originalTrip.missionFrequency / 100.0;
  }

  final TextEditingController titleController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  int? _people;
  double _brave = 0.5;
  double _density = 0.5;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  int? get people => _people;
  double get brave => _brave;
  double get density => _density;

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }
  void setPeople(int? value) {
    _people = value;
    notifyListeners();
  }
  void setBrave(double value) {
    _brave = value;
    notifyListeners();
  }
  void setDensity(double value) {
    _density = value;
    notifyListeners();
  }

  Future<void> saveEditTrip() async {
    final trip = Trip(
      id: originalTrip.id,
      userId: originalTrip.userId,
      title: titleController.text,
      startDate: _startDate!,
      endDate: _endDate!,
      destination: destinationController.text,
      personCount: _people ?? 1,
      braveLevel: (_brave * 10).toInt(),
      missionFrequency: (_density * 100).toInt(),
      createdAt: originalTrip.createdAt,
      updatedAt: DateTime.now(),
      totalMissions: originalTrip.totalMissions,
      completedMissions: originalTrip.completedMissions,
    );
    await repository.updateTrip(trip);
    tripProvider.setTrips(
      tripProvider.trips.map<Trip>((t) => t.id == trip.id ? trip : t).toList(),
    );
  }
} 