import 'package:flutter/material.dart';
import '../../../config/color_system.dart';
import '../../../config/font_system.dart';

class ProfileView extends StatelessWidget {
  final String? userId;
  
  const ProfileView({
    super.key,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          userId != null ? '사용자 ID: $userId' : '프로필 페이지입니다.',
          style: AppFonts.body1,
        ),
      ),
    );
  }
} 