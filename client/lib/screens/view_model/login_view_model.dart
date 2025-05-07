import 'package:flutter/material.dart';
import '../../data/repository/auth_repository.dart';
import '../../core/provider/user_provider.dart';
import '../../data/repository/auth_repository_impl.dart';

/// [LoginViewModel] - LoginView에서 사용
class LoginViewModel extends ChangeNotifier {
  final AuthRepository authRepository;
  final UserProvider userProvider;

  LoginViewModel({required this.authRepository, required this.userProvider});

  // ──────────────────────────────
  // 1. 상태 변수 (State Variables)
  // ──────────────────────────────
  // final GoogleSignIn _googleSignIn = GoogleSignIn();
  // 로그인 상태, 사용자 정보 등 필요시 추가

  // ──────────────────────────────
  // 2. 생성자 (Constructor)
  // ──────────────────────────────
  // LoginViewModel();

  // ──────────────────────────────
  // 3. 상태 변경 메서드 (State Mutators)
  // ──────────────────────────────
  // void setUser(User user) { ... notifyListeners(); }

  // ──────────────────────────────
  // 4. 비즈니스 로직/비동기 처리 (Business Logic/Async)
  // ──────────────────────────────
  Future<bool> signInWithGoogle(BuildContext context) async {
    final success = await authRepository.signInWithGoogle(context, userProvider);
    return success;
  }

  Future<AuthResult> signInWithGoogleWithError(BuildContext context) async {
    return await (authRepository as dynamic).signInWithGoogleWithError(context, userProvider);
  }

  // ──────────────────────────────
  // 5. 기타 유틸리티/초기화/정리 (Utility/Dispose)
  // ──────────────────────────────
  // void signOut() async { ... }
} 