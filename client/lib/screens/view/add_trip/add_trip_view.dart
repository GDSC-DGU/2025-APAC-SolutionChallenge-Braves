import 'package:flutter/material.dart';

class AddTripView extends StatefulWidget {
  const AddTripView({super.key});

  @override
  State<AddTripView> createState() => _AddTripViewState();
}

class _AddTripViewState extends State<AddTripView> {
  final _titleController = TextEditingController();
  final _destinationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  int? _people;
  double _brave = 0.5;
  double _density = 0.5;

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
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
              controller: _titleController,
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
              onTap: _pickDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _startDate != null && _endDate != null
                      ? '${_startDate!.toString().split(' ')[0]} - ${_endDate!.toString().split(' ')[0]}'
                      : '여행 시작일 - 종료일 선택',
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('도착 장소', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _destinationController,
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
              value: _people,
              items: List.generate(10, (i) => i + 1)
                  .map((e) => DropdownMenuItem(value: e, child: Text('$e명')))
                  .toList(),
              onChanged: (v) => setState(() => _people = v),
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
              value: _brave,
              onChanged: (v) => setState(() => _brave = v),
              min: 0,
              max: 1,
              divisions: 10,
              label: (_brave * 100).toInt().toString(),
            ),
            const SizedBox(height: 24),
            const Text('미션 빈도', style: TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: _density,
              onChanged: (v) => setState(() => _density = v),
              min: 0,
              max: 1,
              divisions: 10,
              label: (_density * 100).toInt().toString(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // 저장 로직
                  Navigator.pop(context);
                },
                child: const Text('저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 