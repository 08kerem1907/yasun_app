import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme_provider.dart';
import '../constants/colors.dart';
import '../models/activity_model.dart';
import '../models/user_model.dart';
import '../services/activity_service.dart';
import '../services/auth_service_fixed.dart';
import '../services/user_service.dart';
import 'home_screen.dart';

class HomeScreenContent extends StatelessWidget {
  final String role;
  const HomeScreenContent({super.key, required this.role});

  String _timeAgo(DateTime date) {
    final Duration diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} yıl önce';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} ay önce';
    if (diff.inDays > 7) return '${(diff.inDays / 7).floor()} hafta önce';
    if (diff.inDays > 0) return '${diff.inDays} gün önce';
    if (diff.inHours > 0) return '${diff.inHours} saat önce';
    if (diff.inMinutes > 0) return '${diff.inMinutes} dakika önce';
    return 'şimdi';
  }

  String _formatDetailedDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.shield;
      case 'captain':
        return Icons.star;
      case 'user':
        return Icons.person;
      default:
        return Icons.person;
    }
  }

  void _navigateToScoreTable(BuildContext context, UserModel userData) {
    final int scoreTableIndex =
    (userData.isAdmin || userData.isCaptain) ? 5 : 4;
    HomeScreenNavigator.of(context)?.navigateToIndex(scoreTableIndex);
  }

  void _navigateToTaskManagement(BuildContext context, UserModel userData,
      {int initialTab = 0}) {
    const taskIndex = 3;
    HomeScreenNavigator.of(context)
        ?.navigateToIndex(taskIndex, taskTab: initialTab); // ✅ taskTab eklendi
  }

  void _navigateToMyTeam(BuildContext context) {
    HomeScreenNavigator.of(context)?.navigateToIndex(4);
  }

  void _navigateToUsersList(BuildContext context, {int initialTab = 0}) {
    const usersIndex = 4;
    HomeScreenNavigator.of(context)?.navigateToIndex(usersIndex,
        usersTab: initialTab); // ✅ usersTab eklendi
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<UserModel?>(
      stream: authService.getUserDataStream(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: Text('Kullanıcı verileri bulunamadı')));
        }

        final userData = snapshot.data!;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? AppColors.darkBackgroundGradient
                : AppColors.backgroundGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, userData, authService),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeSection(context, userData),
                        const SizedBox(height: 32),
                        if (userData.isAdmin)
                          _buildAdminStatsSection(
                              context, authService, userData),
                        if (userData.isCaptain)
                          _buildCaptainStatsSection(
                              context, userData.uid, authService, userData),
                        if (userData.isUser)
                          _buildUserStatsSection(
                              context, userData.uid, authService, userData),
                        const SizedBox(height: 32),
                        _buildRecentActivitiesSection(context, userData.uid),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(
      BuildContext context, UserModel userData, AuthService authService) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.appBarTheme.backgroundColor ??
            (isDark ? Colors.grey[900] : Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 84,
            height: 84,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Image.asset('assets/logo_yasunapp.png', fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ekip Yönetim Sistemi',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  userData.roleDisplayName,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: theme.iconTheme.color,
            ),
            tooltip: 'Tema Değiştir',
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: theme.iconTheme.color),
            tooltip: 'Çıkış Yap',
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, UserModel userData) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hoş Geldiniz,',
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          userData.displayName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkPrimary.withOpacity(0.15)
                : AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getRoleIcon(userData.role),
                  size: 16,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary),
              const SizedBox(width: 6),
              Text(
                userData.roleDisplayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminStatsSection(
      BuildContext context, AuthService authService, UserModel userData) {
    final userService = UserService();
    final theme = Theme.of(context);

    return FutureBuilder<Map<String, dynamic>>(
      future: Future.wait([
        userService.getUserCount(),
        userService.getActiveTaskCount(authService.currentUser!.uid),
        userService.getSystemScore(),
        userService.getUserCountByRole(),
      ]).then((responses) => {
        'total_users': responses[0] as int,
        'active_tasks': responses[1] as int,
        'system_score': responses[2] as int,
        'captains': (responses[3] as Map<String, int>)['captain'] ?? 0,
      }),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İstatistikler',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Toplam Kullanıcı',
                    stats['total_users'].toString(),
                    Icons.people,
                    AppColors.primary,
                    onTap: () => _navigateToUsersList(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Aktif Görevler',
                    stats['active_tasks'].toString(),
                    Icons.task,
                    AppColors.error,
                    onTap: () => _navigateToTaskManagement(context, userData),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Kaptanlar',
                    stats['captains'].toString(),
                    Icons.star,
                    AppColors.warning,
                    onTap: () => _navigateToUsersList(context, initialTab: 2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Sistem Puanı',
                    stats['system_score'].toString(),
                    Icons.score,
                    AppColors.success,
                    onTap: () => _navigateToScoreTable(context, userData),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCaptainStatsSection(BuildContext context, String captainUid,
      AuthService authService, UserModel userData) {
    final userService = UserService();
    final theme = Theme.of(context);

    return FutureBuilder<Map<String, int>>(
      future: Future.wait([
        userService.getTeamMemberCount(captainUid),
        userService.getCompletedTasksThisMonth(captainUid),
        userService.getTotalScore(captainUid),
      ]).then((responses) => {
        'team_members': responses[0],
        'completed_tasks_this_month': responses[1],
        'total_score': responses[2],
      }),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final teamStats = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kaptan İstatistikleri',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Ekip Üyeleri',
                    teamStats['team_members'].toString(),
                    Icons.people_alt,
                    AppColors.primary,
                    onTap: () => _navigateToMyTeam(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Tamamlanan Görevler',
                    teamStats['completed_tasks_this_month'].toString(),
                    Icons.check_circle,
                    AppColors.success,
                    onTap: () => _navigateToTaskManagement(context, userData,
                        initialTab: 2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              context,
              'Toplam Puan',
              teamStats['total_score'].toString(),
              Icons.score,
              AppColors.warning,
              onTap: () => _navigateToScoreTable(context, userData),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserStatsSection(BuildContext context, String userUid,
      AuthService authService, UserModel userData) {
    final userService = UserService();
    final theme = Theme.of(context);

    return FutureBuilder<Map<String, int>>(
      future: Future.wait([
        userService.getActiveTaskCount(userUid),
        userService.getCompletedTaskCount(userUid),
        userService.getTotalScore(userUid),
      ]).then((responses) => {
        'active_tasks': responses[0],
        'completed_tasks': responses[1],
        'total_score': responses[2],
      }),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userStats = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Üye İstatistikleri',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Aktif Görevlerim',
                    userStats['active_tasks'].toString(),
                    Icons.assignment,
                    AppColors.primary,
                    onTap: () => _navigateToTaskManagement(context, userData),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Yapılan Görevler',
                    userStats['completed_tasks'].toString(),
                    Icons.check_circle_outline,
                    AppColors.error,
                    onTap: () => _navigateToTaskManagement(context, userData,
                        initialTab: 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              context,
              'Toplam Puan',
              userStats['total_score'].toString(),
              Icons.score,
              AppColors.warning,
              onTap: () => _navigateToScoreTable(context, userData),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivitiesSection(
      BuildContext context, String currentUserId) {
    final activityService = ActivityService();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Son Aktiviteler',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<ActivityModel>>(
          stream: activityService.getRecentActivities(currentUserId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Aktivite yüklenirken hata oluştu: ${snapshot.error}',
                  style: theme.textTheme.bodySmall,
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'Henüz bir aktivite bulunmamaktadır.',
                  style: theme.textTheme.bodySmall,
                ),
              );
            }

            final activities = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _buildActivityItem(
                  context,
                  icon: activity.icon,
                  title: activity.title,
                  subtitle: activity.subtitle,
                  time: _timeAgo(activity.timestamp),
                  color: activity.color,
                  activity: activity,
                  isLastItem: index == activities.length - 1,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(
      BuildContext context,
      String title,
      String value,
      IconData icon,
      Color color, {
        VoidCallback? onTap,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required String time,
        required Color color,
        required ActivityModel activity,
        bool isLastItem = false,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showActivityDetails(context, activity),
      child: Container(
        margin: EdgeInsets.only(bottom: isLastItem ? 0 : 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.18 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(time, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  void _showActivityDetails(BuildContext context, ActivityModel activity) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: activity.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(activity.icon, color: activity.color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDetailedDateTime(activity.timestamp),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: activity.color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: activity.color.withOpacity(0.12)),
                ),
                child: Text(
                  activity.subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tarih ve Saat',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDetailedDateTime(activity.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat', style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
