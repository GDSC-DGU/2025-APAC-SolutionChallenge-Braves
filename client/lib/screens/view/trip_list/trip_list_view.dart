import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/trip_list_view_model.dart';
import '../../common/trip_card.dart';
import '../../common/new_trip_button.dart';
import '../add_trip/add_trip_view.dart';
import '../../view_model/add_trip_view_model.dart';
import '../../../data/repository/trip_repository.dart';
import '../../../core/provider/trip_provider.dart';

class TripListView extends StatelessWidget {
  final GlobalKey<TripListViewBodyState>? bodyKey;
  const TripListView({super.key, this.bodyKey});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TripListViewModel(),
      child: TripListViewBody(key: bodyKey),
    );
  }
}

class TripListViewBody extends StatefulWidget {
  const TripListViewBody({Key? key}) : super(key: key);

  @override
  State<TripListViewBody> createState() => TripListViewBodyState();
}

class TripListViewBodyState extends State<TripListViewBody> {
  bool _initialized = false;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final viewModel = context.read<TripListViewModel>();
      viewModel.init(context);
      _initialized = true;
      fetchTrips();
    }
  }

  Future<void> fetchTrips() async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      await context.read<TripListViewModel>().fetchTrips();
    } finally {
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TripListViewModel>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          NewTripButton(
            onPressed: viewModel.hasOngoingTrip
                ? null
                : () async {
                    final addTripViewModel = AddTripViewModel(
                      repository: context.read<TripRepository>(),
                      tripProvider: context.read<TripProvider>(),
                    );
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddTripView(viewModel: addTripViewModel)),
                    );
                    if (result == true) {
                      fetchTrips();
                    }
                  },
          ),
          if (viewModel.hasOngoingTrip)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'You cannot add a new trip because you have an ongoing trip.',
                style: TextStyle(color: Color(0xFFB8B741), fontSize: 12),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: viewModel.filteredTrips.length,
              itemBuilder: (context, index) {
                final trip = viewModel.filteredTrips[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TripCard(
                    trip: trip,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 