import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../core/provider/user_provider.dart';
import '../../data/repository/mission_repository.dart';
import '../../screens/view/trip_progress/trip_progress_true_view.dart';
import '../../core/provider/trip_provider.dart';

// 백그라운드 메시지 핸들러
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('=== 백그라운드 메시지 수신 ===');
  print('메시지 데이터: ${message.data}');
  print('메시지 알림: ${message.notification?.title} - ${message.notification?.body}');
  print('=== 백그라운드 메시지 수신 종료 ===');
  // data-only 메시지일 때 직접 알림 띄우기
  if (message.data.isNotEmpty) {
    await FCMService.showMissionProposalNotification(message);
  }
}

/// FCM(Firebase Cloud Messaging) 서비스를 관리하는 클래스
/// 알림 표시, 메시지 처리, 토큰 관리 등의 기능을 제공합니다.
class FCMService {
  /// 로컬 알림을 관리하는 플러그인 인스턴스
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  /// Firebase Messaging 인스턴스
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  /// 전역 네비게이션 키 - 알림 클릭 시 화면 전환에 사용
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// 알림 채널 ID 상수
  static const String _channelId = 'mission_proposal_channel';
  static const String _channelName = '미션 제안';
  static const String _channelDescription = '미션 제안 수락/거절 알림';

  /// FCM 서비스 초기화
  /// 로컬 알림 설정과 FCM 설정을 수행합니다.
  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        print('Firebase가 초기화되지 않았습니다.');
        return;
      }

      print('=== FCM 서비스 초기화 시작 ===');
      
      // 백그라운드 메시지 핸들러 등록
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // 로컬 알림 초기화
      await _initLocalNotifications();
      
      // FCM 설정
      await _setupFCM();
      
      print('=== FCM 서비스 초기화 완료 ===');
    } catch (e) {
      print('FCM 서비스 초기화 중 오류 발생: $e');
    }
  }

  /// 로컬 알림 초기화
  /// 안드로이드 플랫폼에 대한 알림 설정을 구성합니다.
  static Future<void> _initLocalNotifications() async {
    try {
      print('=== 로컬 알림 초기화 시작 ===');
      
      const AndroidInitializationSettings initializationSettingsAndroid = 
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const InitializationSettings initializationSettings = 
          InitializationSettings(android: initializationSettingsAndroid);
      
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final existingChannels = await androidPlugin.getNotificationChannels();
        print('기존 알림 채널 목록: ${existingChannels?.map((c) => c.id).toList()}');
        
        await androidPlugin.createNotificationChannel(channel);
        print('알림 채널 생성 성공 - ID: $_channelId');
        
        // 생성된 채널 확인
        final channels = await androidPlugin.getNotificationChannels();
        if (channels != null) {
          final createdChannel = channels.firstWhere(
            (c) => c.id == _channelId,
            orElse: () => const AndroidNotificationChannel('', '', importance: Importance.low),
          );
          if (createdChannel.id.isNotEmpty) {
            print('생성된 채널 확인 성공 - ID: ${createdChannel.id}, 이름: ${createdChannel.name}');
          } else {
            print('생성된 채널을 찾을 수 없음 - ID: $_channelId');
          }
        }
      } else {
        print('알림 채널 생성 실패: Android 플러그인을 찾을 수 없음');
      }
      
      print('=== 로컬 알림 초기화 완료 ===');
    } catch (e) {
      print('로컬 알림 초기화 중 오류 발생: $e');
    }
  }

  /// FCM 설정
  /// 알림 권한 요청, 토큰 관리, 메시지 리스너 설정을 수행합니다.
  static Future<void> _setupFCM() async {
    try {
      print('=== FCM 설정 시작 ===');
      
      // 알림 권한 요청
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      print('FCM 권한 상태: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // FCM 토큰 발급 및 서버 전송
        await _handleFCMToken();
        
        // 메시지 리스너 설정
        _setupMessageListeners();
      } else {
        print('FCM 권한이 거부되었습니다.');
      }
      
      print('=== FCM 설정 완료 ===');
    } catch (e) {
      print('FCM 설정 중 오류 발생: $e');
    }
  }

  /// FCM 토큰 관리
  static Future<void> _handleFCMToken() async {
    try {
      final token = await _messaging.getToken();
      print('FCM 토큰 발급: $token');

      if (token != null) {
        await _sendTokenToServer(token);
      }

      // 토큰 갱신 리스너
      _messaging.onTokenRefresh.listen((newToken) async {
        print('FCM 토큰 갱신: $newToken');
        await _sendTokenToServer(newToken);
      });
    } catch (e) {
      print('FCM 토큰 관리 중 오류 발생: $e');
    }
  }

  /// 토큰 서버 전송
  static Future<void> _sendTokenToServer(String token) async {
    final context = navigatorKey.currentContext;
    if (context != null) {
      try {
        final userProvider = context.read<UserProvider>();
        await userProvider.sendFcmTokenToServer(token);
        print('FCM 토큰 서버 전송 성공');
      } catch (e) {
        print('FCM 토큰 서버 전송 실패: $e');
      }
    } else {
      print('FCM 토큰 서버 전송 실패: context를 찾을 수 없음');
    }
  }

  /// 메시지 리스너 설정
  static void _setupMessageListeners() {
    // Foreground 메시지 처리
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('=== Foreground 메시지 수신 ===');
      print('메시지 데이터: ${message.data}');
      print('메시지 알림: ${message.notification?.title} - ${message.notification?.body}');
      print('=== Foreground 메시지 수신 종료 ===');

      if (message.data['proposalId'] != null) {
        await _showMissionProposalNotification(message);
      }
    });

    // 백그라운드/종료 상태에서 알림 클릭 처리
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('=== 알림 클릭 처리 ===');
      print('메시지 데이터: ${message.data}');
      print('=== 알림 클릭 처리 종료 ===');
      _handleMessageOpenedApp(message);
    });

    // 초기 알림 처리
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('=== 초기 메시지 처리 ===');
        print('메시지 데이터: ${message.data}');
        print('=== 초기 메시지 처리 종료 ===');
        _handleMessageOpenedApp(message);
      }
    });
  }

  /// 미션 제안 알림 표시
  /// 수락/거절 액션 버튼이 포함된 알림을 표시합니다.
  static Future<void> _showMissionProposalNotification(RemoteMessage message) async {
    final proposalId = message.data['proposalId'];
    final missionTitle = message.data['missionTitle'] ?? '새로운 미션 제안';
    final missionContent = message.data['missionContent'] ?? '';

    print('알림 표시 시도 - 제목: $missionTitle, 내용: $missionContent');

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('accept', 'Accept', showsUserInterface: true, cancelNotification: true),
        AndroidNotificationAction('reject', 'Reject', showsUserInterface: true, cancelNotification: true),
      ],
    );
    const NotificationDetails platformChannelSpecifics = 
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    try {
      await _notificationsPlugin.show(
        0,
        missionTitle,
        missionContent,
        platformChannelSpecifics,
        payload: proposalId,
      );
      print('알림 표시 성공');
    } catch (e) {
      print('알림 표시 실패: $e');
    }
  }

  /// 알림 응답 처리
  /// 사용자가 알림의 액션 버튼을 클릭했을 때 호출됩니다.
  static Future<void> _onDidReceiveNotificationResponse(NotificationResponse response) async {
    final actionId = response.actionId;
    final proposalId = response.payload;
    final context = navigatorKey.currentContext;
    if (context == null || proposalId == null) return;

    if (actionId == 'accept') {
      await _handleMissionAccept(context, proposalId);
    } else if (actionId == 'reject') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mission Rejected')),
      );
    }
  }

  /// 미션 수락 처리
  /// 미션 수락 API를 호출하고 성공 시 해당 미션 화면으로 이동합니다.
  static Future<void> _handleMissionAccept(BuildContext context, String proposalId) async {
    final missionRepository = context.read<MissionRepository>();
    try {
      final decoded = await missionRepository.acceptMissionProposal(proposalId);
      if (decoded['success'] == true) {
        final missionId = decoded['missionId'];
        final title = decoded['title'] ?? '';
        final content = decoded['content'] ?? '';
        final tripProvider = context.read<TripProvider>();
        final trip = tripProvider.trips.isNotEmpty ? tripProvider.trips.first : null;
        
        if (trip != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TripProgressTrueView(
                trip: trip,
                proposalId: proposalId,
                missionTitle: title,
                missionContent: content,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip Information Not Found')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decoded['msg'] ?? 'Mission Accept Failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mission Accept Error: $e')),
      );
    }
  }

  /// 백그라운드/종료 상태에서 알림 클릭 처리
  /// 앱이 백그라운드나 종료 상태일 때 알림을 클릭했을 때 호출됩니다.
  static Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    final data = message.data;
    final tripId = data['tripId'];
    final proposalId = data['proposalId'];
    final missionTitle = data['missionTitle'];
    final missionContent = data['missionContent'];

    if (tripId != null && proposalId != null) {
      final context = navigatorKey.currentContext!;
      final result = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mission Proposal'),
          content: const Text('Accept the new mission?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Reject'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Accept'),
            ),
          ],
        ),
      );

      if (result == true) {
        await _handleMissionAccept(context, proposalId);
      }
    }
  }

  /// 외부에서 호출할 수 있도록 알림 표시 메서드 공개
  static Future<void> showMissionProposalNotification(RemoteMessage message) async {
    final proposalId = message.data['proposalId'] ?? message.data['proposal_id'];
    final missionTitle = message.data['missionTitle'] ?? message.data['mission_title'] ?? '새로운 미션 제안';
    final missionContent = message.data['missionContent'] ?? message.data['mission_content'] ?? '';

    print('알림 표시 시도 - 제목: $missionTitle, 내용: $missionContent');

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('accept', 'Accept', showsUserInterface: true, cancelNotification: true),
        AndroidNotificationAction('reject', 'Reject', showsUserInterface: true, cancelNotification: true),
      ],
    );
    const NotificationDetails platformChannelSpecifics = 
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    try {
      await _notificationsPlugin.show(
        0,
        missionTitle,
        missionContent,
        platformChannelSpecifics,
        payload: proposalId,
      );
      print('알림 표시 성공');
    } catch (e) {
      print('알림 표시 실패: $e');
    }
  }
} 