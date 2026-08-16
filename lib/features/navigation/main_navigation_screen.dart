import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../auth/models/user_profile.dart';
import '../chat/screens/chat_screen.dart';
import '../discover/repositories/discover_repository.dart';
import '../discover/screens/discover_screen.dart';
import '../memories/screens/memories_timeline_screen.dart';
import '../plans/screens/plans_hub_screen.dart';
import '../profile/screens/my_profile_screen.dart';
import '../us_dashboard/screens/us_home_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  StreamSubscription? _sparkSubscription;

  final List<Widget> _screens = const [
    UsHomeScreen(),
    DiscoverScreen(),
    MemoriesTimelineScreen(),
    PlansHubScreen(),
    MyProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _sparkSubscription = DiscoverRepository().sparkUpdates.listen((event) {
      if (!mounted) return;
      if (event['type'] == 'spark_accepted' && event['triggerNotification'] == true) {
        final user = event['user'] as UserProfile?;
        final userName = user?.fullName ?? 'A connection';

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.favorite_rounded, color: AppColors.roseDust, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                      children: [
                        const TextSpan(text: '🎉 '),
                        TextSpan(
                          text: userName,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.champagne),
                        ),
                        const TextSpan(text: ' accepted your Spark request! You can now send messages.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E2230),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF2E344A), width: 1.2),
            ),
            duration: const Duration(milliseconds: 3200),
            dismissDirection: DismissDirection.horizontal,
            action: user != null
                ? SnackBarAction(
                    label: 'Message 💬',
                    textColor: AppColors.champagne,
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(targetUser: user),
                        ),
                      );
                    },
                  )
                : null,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _sparkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.champagne,
        unselectedItemColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        onTap: (index) {
          HapticFeedback.selectionClick();
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline_rounded),
            activeIcon: Icon(Icons.favorite_rounded),
            label: 'Us',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore_rounded),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome_rounded),
            label: 'Memories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today_rounded),
            label: 'Plans',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
