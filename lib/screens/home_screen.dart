import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import '../models/user_model.dart';
import '../services/auth_service_fixed.dart';

import 'home_screen_content.dart';
import 'duyurular_screen.dart';
import 'profile_screen.dart';
import 'task_management_screen.dart';
import 'users_list_screen.dart';
import 'my_team_screen.dart';
import 'score_table_screen.dart';

// InheritedWidget ile navigation state'i paylaşmak için
class HomeScreenNavigator extends InheritedWidget {
  final Function(int, {int? taskTab, int? usersTab}) navigateToIndex;

  const HomeScreenNavigator({
    super.key,
    required this.navigateToIndex,
    required super.child,
  });

  static HomeScreenNavigator? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HomeScreenNavigator>();
  }

  @override
  bool updateShouldNotify(HomeScreenNavigator oldWidget) {
    return false;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _taskManagementTab = 0;
  int _usersListTab = 0;

  // Her rol için ekran listelerini dinamik olarak oluştur
  List<Widget> _getScreensForRole(UserModel userData) {
    if (userData.isAdmin) {
      return [
        const HomeScreenContent(role: 'admin'),
        const DuyurularScreen(),
        const ProfileScreen(),
        TaskManagementScreen(initialTabIndex: _taskManagementTab),
        UsersListScreen(initialTab: _usersListTab),
        const ScoreTableScreen(),
      ];
    } else if (userData.isCaptain) {
      return [
        const HomeScreenContent(role: 'captain'),
        const DuyurularScreen(),
        const ProfileScreen(),
        TaskManagementScreen(initialTabIndex: _taskManagementTab),
        const MyTeamScreen(),
        const ScoreTableScreen(),
      ];
    } else {
      return [
        const HomeScreenContent(role: 'user'),
        const DuyurularScreen(),
        const ProfileScreen(),
        TaskManagementScreen(initialTabIndex: _taskManagementTab),
        const ScoreTableScreen(),
      ];
    }
  }

  // Her rol için ikon listesini oluştur
  List<Widget> _getNavigationItems(UserModel userData) {
    List<Widget> commonIcons = [
      const Icon(Icons.home, size: 30, color: Colors.white),
      const Icon(Icons.notifications, size: 30, color: Colors.white),
      const Icon(Icons.person, size: 30, color: Colors.white),
    ];

    if (userData.isAdmin) {
      return [
        ...commonIcons,
        const Icon(Icons.assignment, size: 30, color: Colors.white),
        const Icon(Icons.group, size: 30, color: Colors.white),
        const Icon(Icons.leaderboard, size: 30, color: Colors.white),
      ];
    } else if (userData.isCaptain) {
      return [
        ...commonIcons,
        const Icon(Icons.assignment, size: 30, color: Colors.white),
        const Icon(Icons.people_alt, size: 30, color: Colors.white),
        const Icon(Icons.leaderboard, size: 30, color: Colors.white),
      ];
    } else {
      return [
        ...commonIcons,
        const Icon(Icons.assignment, size: 30, color: Colors.white),
        const Icon(Icons.leaderboard, size: 30, color: Colors.white),
      ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Farklı bir ekrana geçildiğinde tab'ları sıfırla
      if (index != 3) _taskManagementTab = 0;
      if (index != 4) _usersListTab = 0;
    });
  }

  // Tab parametreleri ile navigasyon
  void _navigateToIndex(int index, {int? taskTab, int? usersTab}) {
    setState(() {
      _selectedIndex = index;
      if (taskTab != null) {
        _taskManagementTab = taskTab;
      }
      if (usersTab != null) {
        _usersListTab = usersTab;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ YENİ: Tema renklerine erişim
    final colorScheme = Theme.of(context).colorScheme;
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<UserModel?>(
      stream: authService.getUserDataStream(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('Kullanıcı verileri bulunamadı')),
          );
        }

        final userData = snapshot.data!;
        final screens = _getScreensForRole(userData);

        // Index sınırları kontrolü
        if (_selectedIndex >= screens.length) {
          _selectedIndex = 0;
        }

        return HomeScreenNavigator(
          navigateToIndex: _navigateToIndex,
          child: PopScope(
            canPop: _selectedIndex ==
                0, // Sadece ana sayfadayken (index 0) uygulamadan çıkışa izin ver
            onPopInvoked: (didPop) {
              if (didPop) return;

              // Eğer ana sayfada değilsek, ana sayfaya yönlendir
              if (_selectedIndex != 0) {
                setState(() {
                  _selectedIndex = 0;
                });
              }
            },
            child: Scaffold(
              bottomNavigationBar: CurvedNavigationBar(
                // ✅ DEĞİŞTİ: Tema renklerini kullan
                backgroundColor: colorScheme.background,
                color: colorScheme.primary,
                buttonBackgroundColor: colorScheme.primary,
                height: 50,
                index: _selectedIndex,
                items: _getNavigationItems(userData),
                onTap: _onItemTapped,
              ),
              body: screens[_selectedIndex],
            ),
          ),
        );
      },
    );
  }
}
