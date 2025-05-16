import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/profile_view_model.dart';
import '../../../config/font_system.dart';
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
    final viewModel = ProfileViewModel(authRepository: authRepository, userProvider: userProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF56BC6C),
        elevation: 0,
        centerTitle: true,
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
                  ? const Icon(Icons.person, size: 48, color: Color(0xFF56BC6C))
                  : null,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              userProvider.username ?? '-',
              style: AppFonts.headline1.copyWith(color: const Color(0xFF56BC6C)),
            ),
            const SizedBox(height: 8),
            Text(
              userProvider.email ?? '-',
              style: AppFonts.body2.copyWith(color: Color(0xFFB8B741)),
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout, color: Color(0xFFB8B741)),
                    label: const Text('Logout', style: TextStyle(color: Color(0xFFB8B741))),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFB8B741),
                      side: const BorderSide(color: Color(0xFFB8B741)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      await viewModel.logout(context);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 