import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/trip_list_view_model.dart';
import '../../../config/color_system.dart';
import '../../common/trip_card.dart';
import '../../common/new_trip_button.dart';
import '../add_trip/add_trip_view.dart';
import '../../../core/provider/trip_provider.dart';
import '../../../data/datasource/trip_datasource.dart';
import '../../../data/repository/trip_repository.dart';
import '../../../data/repository/trip_repository_impl.dart';
import '../../../core/provider/user_provider.dart';

class TripListView extends StatelessWidget {
  const TripListView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TripProvider()),
        Provider<TripDataSource>(create: (context) => TripDataSourceImpl(context.read<UserProvider>())),
        Provider<TripRepository>(
          create: (context) => TripRepositoryImpl(context.read<TripDataSource>()),
        ),
        ChangeNotifierProvider(
          create: (context) => TripListViewModel(
            repository: context.read<TripRepository>(),
            tripProvider: context.read<TripProvider>(),
          ),
        ),
      ],
      child: const _TripListViewBody(),
    );
  }
}

class _TripListViewBody extends StatefulWidget {
  const _TripListViewBody();

  @override
  State<_TripListViewBody> createState() => _TripListViewBodyState();
}

class _TripListViewBodyState extends State<_TripListViewBody> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<TripListViewModel>().fetchTrips());
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
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
              itemCount: tripProvider.trips.length,
              itemBuilder: (context, index) {
                final trip = tripProvider.trips[index];
                return TripCard(
                  title: trip.title,
                  missionCount: '0/0',
                  date: '${trip.startDate.toString().split(' ')[0]} - ${trip.endDate.toString().split(' ')[0]}',
                  travelId: trip.id,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 