import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/profile_view_model.dart';
import '../../../config/color_system.dart';
import '../../../config/font_system.dart';
import 'package:intl/intl.dart';
import '../login/login_view.dart';
import '../../../core/provider/user_provider.dart';
import '../../../data/repository/auth_repository.dart';

class ProfileView extends StatelessWidget {
  final String? userId;
  
  const ProfileView({
    super.key,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return _ProfileViewBody(userId: userId);
  }
}

class _ProfileViewBody extends StatelessWidget {
  final String? userId;
  const _ProfileViewBody({this.userId});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final authRepository = context.read<AuthRepository>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('프로필'),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () async {
              await authRepository.logout(context, userProvider);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginView()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage: userProvider.profileImage != null && userProvider.profileImage!.isNotEmpty
                  ? NetworkImage(userProvider.profileImage!)
                  : null,
              child: userProvider.profileImage == null || userProvider.profileImage!.isEmpty
                  ? const Icon(Icons.person, size: 48)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              userProvider.username ?? '-',
              style: AppFonts.headline1,
            ),
            const SizedBox(height: 8),
            Text(
              userProvider.email ?? '-',
              style: AppFonts.body2.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 20),
                        const SizedBox(width: 8),
                        Text('유저ID: ', style: AppFonts.body1),
                        Text(userProvider.userId?.toString() ?? '-', style: AppFonts.body2),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.verified_user, size: 20),
                        const SizedBox(width: 8),
                        Text('토큰 타입: ', style: AppFonts.body1),
                        Text(userProvider.tokenType ?? '-', style: AppFonts.body2),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 