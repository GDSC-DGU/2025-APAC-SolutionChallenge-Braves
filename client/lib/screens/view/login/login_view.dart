import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/login_view_model.dart';
import '../profile/profile_view.dart';
import '../../../core/provider/user_provider.dart';
import '../../../data/repository/auth_repository.dart';
import '../../../data/repository/auth_repository_impl.dart';
import '../main_view.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => AuthRepositoryImpl()),
        ChangeNotifierProvider(
          create: (context) => LoginViewModel(
            authRepository: context.read<AuthRepository>(),
            userProvider: context.read<UserProvider>(),
          ),
        ),
      ],
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
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in with Google'),
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
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(220, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
} 