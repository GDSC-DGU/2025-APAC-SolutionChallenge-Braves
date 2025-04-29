import 'package:flutter/material.dart';
import '../../../config/color_system.dart';
import '../../../config/font_system.dart';

class TripProgressView extends StatelessWidget {
  final String? status;
  
  const TripProgressView({
    super.key,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          status != null ? '상태: $status' : '진행중인 여행이 없습니다.',
          style: AppFonts.body1,
        ),
      ),
    );
  }
} 