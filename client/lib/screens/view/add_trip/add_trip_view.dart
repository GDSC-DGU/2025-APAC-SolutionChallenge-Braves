import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/add_trip_view_model.dart';
import '../../../core/provider/trip_provider.dart';
import '../../../data/datasource/trip_datasource.dart';
import '../../../data/repository/trip_repository.dart';
import '../../../data/repository/trip_repository_impl.dart';
import '../../../core/provider/user_provider.dart';

class AddTripView extends StatelessWidget {
  const AddTripView({super.key});

  Future<void> _pickDateRange(BuildContext context, AddTripViewModel model) async {
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: Provider.of<TripProvider>(context, listen: false)),
        Provider<TripRepository>(create: (context) => TripRepositoryImpl(TripDataSourceImpl(context.read<UserProvider>()))),
        ChangeNotifierProvider(
          create: (context) => AddTripViewModel(
            repository: context.read<TripRepository>(),
            tripProvider: context.read<TripProvider>(),
          ),
        ),
      ],
      child: const _AddTripViewBody(),
    );
  }
}

class _AddTripViewBody extends StatelessWidget {
  const _AddTripViewBody();

  Future<void> _pickDateRange(BuildContext context, AddTripViewModel model) async {
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
    return Consumer<AddTripViewModel>(
      builder: (context, model, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    '새로운 여행 추가',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('여행 제목', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: model.titleController,
                  decoration: const InputDecoration(
                    hintText: '여행 제목을 입력하세요',
                    filled: true,
                    fillColor: Color(0xFFF5F5F5),
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 24),
                const Text('여행 기간', style: TextStyle(fontWeight: FontWeight.bold)),
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
                          : '여행 시작일 - 종료일 선택',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('도착 장소', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: model.destinationController,
                  decoration: const InputDecoration(
                    hintText: '여행 도착 장소를 입력하세요',
                    filled: true,
                    fillColor: Color(0xFFF5F5F5),
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 24),
                const Text('인원', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: model.people,
                  items: List.generate(10, (i) => i + 1)
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e명')))
                      .toList(),
                  onChanged: model.setPeople,
                  decoration: const InputDecoration(
                    hintText: '여행 인원을 선택하세요',
                    filled: true,
                    fillColor: Color(0xFFF5F5F5),
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 24),
                const Text('brave 정도', style: TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: model.brave,
                  onChanged: model.setBrave,
                  min: 0,
                  max: 1,
                  divisions: 10,
                  label: (model.brave * 100).toInt().toString(),
                ),
                const SizedBox(height: 24),
                const Text('미션 빈도', style: TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: model.density,
                  onChanged: model.setDensity,
                  min: 0,
                  max: 1,
                  divisions: 10,
                  label: (model.density * 100).toInt().toString(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await model.saveTrip();
                      model.clear();
                      Navigator.pop(context);
                    },
                    child: const Text('저장'),
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