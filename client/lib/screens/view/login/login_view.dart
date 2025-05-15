import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../view_model/login_view_model.dart';
import '../../../core/provider/user_provider.dart';
import '../../../data/repository/auth_repository.dart';
import '../main_view.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LoginViewModel(
        authRepository: context.read<AuthRepository>(),
        userProvider: context.read<UserProvider>(),
      ),
      child: const _LoginViewBody(),
    );
  }
}

class _LoginViewBody extends StatefulWidget {
  const _LoginViewBody();

  @override
  State<_LoginViewBody> createState() => _LoginViewBodyState();
}

class _LoginViewBodyState extends State<_LoginViewBody> {
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final loginViewModel = context.read<LoginViewModel>();
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/bravacation_icon.jpg',
                    height: 200,
                  ),
                  Image.asset(
                    'assets/images/bravacation_logo.png',
                    height: 100,
                  ),
                  const SizedBox(height: 32),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFFB8B741)),
                      ),
                    ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login, color: Colors.white),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Sign in with Google',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        SvgPicture.asset(
                          'assets/images/flat-color-icons_google.svg',
                          height: 24,
                          width: 24,
                        ),
                      ],
                    ),
                    onPressed: () async {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      final result = await loginViewModel.signInWithGoogleWithError(context);
                      setState(() {
                        _isLoading = false;
                      });
                      if (result.success) {
                        if (!mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const MainView()),
                        );
                      } else {
                        setState(() {
                          _error = result.errorMessage ?? '로그인에 실패했습니다. 다시 시도해 주세요.';
                        });
                        if (_error != null && _error!.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_error!)),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF56BC6C),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(220, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFFB8B741), width: 2),
                      ),
                      elevation: 2,
                      shadowColor: const Color(0xFFB8B741),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
} 