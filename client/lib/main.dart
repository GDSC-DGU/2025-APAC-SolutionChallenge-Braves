import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/provider/trip_provider.dart';
import 'screens/view/main_view.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/provider/user_provider.dart';
import 'screens/view/login/login_view.dart';
import 'data/repository/auth_repository.dart';
import 'data/repository/auth_repository_impl.dart';
import 'data/datasource/trip_datasource.dart';
import 'data/repository/trip_repository.dart';
import 'data/repository/trip_repository_impl.dart';
import 'data/repository/mission_repository.dart';
import 'data/datasource/mission_datasource.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/service/background_location_service.dart';
import 'core/service/fcm_service.dart';
import 'screens/view/trip_progress/trip_progress_true_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 환경 변수 로드
    print('환경 변수 로드 시작');
    await dotenv.load(fileName: 'assets/config/.env');
    print('환경 변수 로드 완료');

    // Firebase 초기화
    print('Firebase 초기화 시작');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase 초기화 완료');

    // 서비스 초기화
    print('백그라운드 위치 서비스 초기화 시작');
    await BackgroundLocationService.initialize();
    print('백그라운드 위치 서비스 초기화 완료');

    print('FCM 서비스 초기화 시작');
    await FCMService.initialize();
    print('FCM 서비스 초기화 완료');

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TripProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
          Provider<AuthRepository>(create: (_) => AuthRepositoryImpl()),
          Provider<TripDataSource>(
            create: (context) => TripDataSourceImpl(
              context.read<AuthRepository>(),
              context,
            ),
          ),
          Provider<TripRepository>(
            create: (context) => TripRepositoryImpl(
              context.read<TripDataSource>(),
            ),
          ),
          Provider<MissionDataSource>(
            create: (context) => MissionDataSourceImpl(
              context.read<AuthRepository>(),
              context,
            ),
          ),
          Provider<MissionRepository>(
            create: (context) => MissionRepositoryImpl(
              context.read<MissionDataSource>(),
            ),
          ),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    print('앱 초기화 중 오류 발생: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: FCMService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Braves',
      theme: ThemeData(
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      navigatorObservers: [routeObserver],
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final authRepository = context.read<AuthRepository>();
    final userProvider = context.read<UserProvider>();
    await userProvider.loadFromPrefs();
    
    final success = await authRepository.tryAutoLogin(context, userProvider);
    if (!mounted) return;

    if (userProvider.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainView()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}