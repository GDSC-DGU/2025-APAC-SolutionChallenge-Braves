import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/trip_progress_view_model.dart';
import '../../../config/color_system.dart';
import './trip_progress_true_view.dart';
import './trip_progress_false_view.dart';
import '../../../core/provider/trip_provider.dart';

class TripProgressView extends StatefulWidget {
  final GlobalKey<TripProgressViewState>? viewKey;
  const TripProgressView({super.key, this.viewKey});

  @override
  State<TripProgressView> createState() => TripProgressViewState();
}

class TripProgressViewState extends State<TripProgressView> {
  late TripProgressViewModel viewModel;
  late TripProvider tripProvider;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    tripProvider = Provider.of<TripProvider>(context);
    if (!_initialized) {
      viewModel = TripProgressViewModel(tripProvider: tripProvider);
      _initialized = true;
    } else {
      viewModel.updateOngoingTrip(tripProvider);
    }
  }

  void refreshProgress() {
    if (mounted) {
      viewModel.updateOngoingTrip(tripProvider);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TripProgressViewModel>.value(
      value: viewModel,
      child: Consumer<TripProgressViewModel>(
        builder: (context, model, _) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: model.hasOngoingTrip
                ? TripProgressTrueView(trip: model.ongoingTrip!)
                : const TripProgressFalseView(),
          );
        },
      ),
    );
  }
} 