import 'package:flutter/material.dart';
import '../../data/models/trip.dart';

class TripProvider with ChangeNotifier {
  List<Trip> _trips = [];
  List<Trip> get trips => _trips;

  void setTrips(List<Trip> trips) {
    _trips = trips;
    notifyListeners();
  }

  void addTrip(Trip trip) {
    _trips.add(trip);
    notifyListeners();
  }

  void deleteTrip(int tripId) {
    _trips.removeWhere((trip) => trip.id == tripId);
    notifyListeners();
  }
} 