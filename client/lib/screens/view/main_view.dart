import 'package:flutter/material.dart';
import '../../config/app_page.dart';
import '../common/bottom_nav_bar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import '../../core/provider/user_provider.dart';
import '../view/trip_list/trip_list_view.dart';
import '../view/trip_progress/trip_progress_view.dart';


class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  int _selectedIndex = 0;

  final GlobalKey<TripListViewBodyState> _tripListKey = GlobalKey<TripListViewBodyState>();
  final GlobalKey<TripProgressViewState> _tripProgressKey = GlobalKey<TripProgressViewState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _sendFcmTokenIfNeeded();
    _pages = [
      TripListView(bodyKey: _tripListKey),
      TripProgressView(viewKey: _tripProgressKey),
      AppPage.profile,
    ];
  }

  void _sendFcmTokenIfNeeded() async {
    final userProvider = context.read<UserProvider>();
    if (userProvider.isLoggedIn) {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await userProvider.sendFcmTokenToServer(token);
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      _tripListKey.currentState?.fetchTrips();
    } else if (index == 1) {
      _tripProgressKey.currentState?.refreshProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
} 