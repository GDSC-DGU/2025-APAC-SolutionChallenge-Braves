import 'package:flutter/material.dart';
import '../view/trip_list/trip_detail_view.dart';
import 'action_button.dart';
import '../../data/models/trip.dart';
import '../view/edit_trip/edit_trip_view.dart';
import '../view_model/trip_list_view_model.dart';
import 'package:provider/provider.dart';

class TripCard extends StatefulWidget {
  final Trip trip;
  const TripCard({
    super.key,
    required this.trip,
  });

  @override
  State<TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<TripCard> with SingleTickerProviderStateMixin {
  double _offset = 0.0;
  bool _isOpen = false;
  static const double maxOffset = 120.0;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _offset += details.delta.dx;
      if (_offset < -maxOffset) _offset = -maxOffset;
      if (_offset > 0) _offset = 0;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    setState(() {
      if (_offset < -maxOffset / 2) {
        _offset = -maxOffset;
        _isOpen = true;
      } else {
        _offset = 0;
        _isOpen = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final now = DateTime.now();
    final canEdit = now.isBefore(trip.startDate);
    final actions = <Widget>[];
    if (canEdit) {
      actions.add(ActionButton(
        icon: Icons.edit,
        label: 'Edit',
        color: Colors.blue,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditTripView(trip: trip),
            ),
          );
        },
      ));
    }
    actions.add(ActionButton(
      icon: Icons.delete,
      label: 'Delete',
      color: Colors.red,
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Trip'),
            content: const Text('Are you sure you want to delete this trip??'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('delete'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await context.read<TripListViewModel>().deleteTrip(trip.id);
        }
      },
    ));

    return SizedBox(
      height: 140,
      child: Stack(
        children: [
          // 배경 버튼 (고정)
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: actions.length == 2
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          actions[0],
                          const SizedBox(height: 8),
                          actions[1],
                        ],
                      )
                    : actions[0],
              ),
            ),
          ),
          // 카드 (슬라이드)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            left: _offset,
            right: -_offset,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TripDetailView(
                      title: trip.title,
                      date: '${trip.startDate.toString().split(' ')[0]} - ${trip.endDate.toString().split(' ')[0]}',
                      missionCount: '${trip.completedMissions}/${trip.totalMissions}',
                      travelId: trip.id,
                      destination: trip.destination,
                    ),
                  ),
                );
              },
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF757575),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Mission Completed: ${trip.completedMissions}/${trip.totalMissions}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${trip.startDate.toString().split(' ')[0]} - ${trip.endDate.toString().split(' ')[0]}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 