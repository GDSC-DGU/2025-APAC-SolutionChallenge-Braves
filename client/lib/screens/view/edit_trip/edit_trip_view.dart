import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/edit_trip_view_model.dart';
import '../../../core/provider/trip_provider.dart';
import '../../../data/repository/trip_repository.dart';
import '../../../data/models/trip.dart';
import '../../../config/color_system.dart';

class EditTripView extends StatelessWidget {
  final Trip trip;
  const EditTripView({super.key, required this.trip});

  Future<void> _pickDateRange(BuildContext context, EditTripViewModel model) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: model.startDate != null && model.endDate != null
          ? DateTimeRange(start: model.startDate!, end: model.endDate!)
          : null,
    );
    if (picked != null) {
      model.setDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EditTripViewModel(
        repository: context.read<TripRepository>(),
        tripProvider: context.read<TripProvider>(),
        originalTrip: trip,
      ),
      child: const _EditTripViewBody(),
    );
  }
}

class _EditTripViewBody extends StatelessWidget {
  const _EditTripViewBody();

  Future<void> _pickDateRange(BuildContext context, EditTripViewModel model) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: model.startDate != null && model.endDate != null
          ? DateTimeRange(start: model.startDate!, end: model.endDate!)
          : null,
    );
    if (picked != null) {
      model.setDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditTripViewModel>(
      builder: (context, model, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Edit Trip'),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF56BC6C),
            elevation: 0,
            automaticallyImplyLeading: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Edit Trip',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF56BC6C)),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Trip Title', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF56BC6C))),
                const SizedBox(height: 8),
                TextField(
                  controller: model.titleController,
                  decoration: const InputDecoration(
                    hintText: 'Enter trip title',
                    filled: true,
                    fillColor: Color(0xFFF5F5F5),
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Trip Period', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF56BC6C))),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _pickDateRange(context, model),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      model.startDate != null && model.endDate != null
                          ? '${model.startDate!.toString().split(' ')[0]} - ${model.endDate!.toString().split(' ')[0]}'
                          : 'Select start and end date',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Destination', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF56BC6C))),
                const SizedBox(height: 8),
                TextField(
                  controller: model.destinationController,
                  decoration: const InputDecoration(
                    hintText: 'Enter destination',
                    filled: true,
                    fillColor: Color(0xFFF5F5F5),
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 24),
                const Text('People', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF56BC6C))),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: model.people,
                  items: List.generate(10, (i) => i + 1)
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e person${e > 1 ? 's' : ''}')))
                      .toList(),
                  onChanged: model.setPeople,
                  decoration: const InputDecoration(
                    hintText: 'Select number of people',
                    filled: true,
                    fillColor: Color(0xFFF5F5F5),
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Brave Level', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF56BC6C))),
                Slider(
                  value: model.brave,
                  onChanged: model.setBrave,
                  min: 0,
                  max: 1,
                  divisions: 10,
                  label: (model.brave * 100).toInt().toString(),
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.secondary,
                ),
                const SizedBox(height: 24),
                const Text('Mission Frequency', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF56BC6C))),
                Slider(
                  value: model.density,
                  onChanged: model.setDensity,
                  min: 0,
                  max: 1,
                  divisions: 10,
                  label: (model.density * 100).toInt().toString(),
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.secondary,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await model.saveEditTrip();
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF56BC6C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFFB8B741), width: 2),
                      ),
                      elevation: 2,
                      shadowColor: const Color(0xFFB8B741),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 