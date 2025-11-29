import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/activity_model.dart';
import '../models/user_model.dart';
import '../services/activity_service.dart';
import '../services/auth_service_fixed.dart';
import '../services/user_service.dart';
import 'home_screen.dart';
import 'user_task_management_screen.dart';
import 'users_list_screen.dart';

class HomeScreenContent extends StatelessWidget {
  final String role;
  const HomeScreenContent({super.key, required this.role});

  String _timeAgo(DateTime date) {
    final Duration diff = DateTime.now().difference(date);
    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()} yıl önce';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()} ay önce';
    } else if (diff.inDays > 7) {
      return '${(diff.inDays / 7).floor()} hafta önce';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} gün önce';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} saat önce';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} dakika önce';
    } else {
      return 'şimdi';
    }
  }

  // Yardımcı metod - HomeScreen'deki bottom navigation ile ScoreTable'a git
  void _navigateToScoreTable(BuildContext context, UserModel userData) {
    int scoreTableIndex;

    if (userData.isAdmin) {
      scoreTableIndex = 5; // Admin için ScoreTableScreen index'i
    } else if (userData.isCaptain) {
      scoreTableIndex = 5; // Kaptan için ScoreTableScreen index'i
    } else {
      scoreTableIndex = 4; // Normal kullanıcı için ScoreTableScreen index'i
    }

    // HomeScreenNavigator kullanarak navigasyon yap
    HomeScreenNavigator.of(context)?.navigateToIndex(scoreTableIndex);
  }

  // Görev yönetim sayfasına git
  void _navigateToTaskManagement(BuildContext context, UserModel userData, {int initialTab = 0}) {
    int taskManagementIndex = 3; // Tüm roller için TaskManagementScreen index'i 3

    // Önce sayfaya git
    HomeScreenNavigator.of(context)?.navigateToIndex(taskManagementIndex);

    // Eğer belirli bir sekmeye gitmek isteniyorsa
    if (initialTab != 0) {
      // Bir sonraki frame'de sekme değişikliğini yap
      Future.delayed(const Duration(milliseconds: 100), () {
        if (context.mounted) {
          TaskManagementNavigator.of(context)?.changeTab(initialTab);
        }
      });
    }
  }

  // Ekibim sayfasına git (Kaptan için)
  void _navigateToMyTeam(BuildContext context) {
    int myTeamIndex = 4; // Kaptan için MyTeamScreen index'i 4
    HomeScreenNavigator.of(context)?.navigateToIndex(myTeamIndex);
  }

  // Kullanıcı listesi sayfasına git (Admin için)
  void _navigateToUsersList(BuildContext context, {int initialTab = 0}) {
    int usersListIndex = 4; // Admin için UsersListScreen index'i 4

    // Önce sayfaya git
    HomeScreenNavigator.of(context)?.navigateToIndex(usersListIndex);

    // Eğer belirli bir sekmeye gitmek isteniyorsa
    if (initialTab != 0) {
      // Bir sonraki frame'de sekme değişikliğini yap
      Future.delayed(const Duration(milliseconds: 100), () {
        if (context.mounted) {
          UsersListNavigator.of(context)?.changeTab(initialTab);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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

        return Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
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
                        _buildWelcomeSection(userData),
                        const SizedBox(height: 32),
                        if (userData.isAdmin) _buildAdminStatsSection(context, authService, userData),
                        if (userData.isCaptain) _buildCaptainStatsSection(context, userData.uid, authService, userData),
                        if (userData.isUser) _buildUserStatsSection(context, userData.uid, authService, userData),
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

  Widget _buildAppBar(BuildContext context, UserModel userData, AuthService authService) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            decoration: const BoxDecoration(
              shape: BoxShape.circle, // istersen bunu da kaldırabiliriz
            ),
            clipBehavior: Clip.antiAlias, // fotoğraf taşmasın diye
            child: Image.asset(
              'assets/logo_yasunapp.png', // kendi fotoğraf yolun
              fit: BoxFit.cover,
            ),
          ),


          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ekip Yönetim Sistemi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  userData.roleDisplayName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
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

  Widget _buildWelcomeSection(UserModel userData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hoş Geldiniz,',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          userData.displayName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getRoleIcon(userData.role),
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                userData.roleDisplayName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminStatsSection(BuildContext context, AuthService authService, UserModel userData) {
    final userService = UserService();

    return FutureBuilder<Map<String, dynamic>>(
      future: Future.wait([
        userService.getUserCount(),
        userService.getActiveTaskCount(authService.currentUser!.uid),
        userService.getSystemScore(),
        userService.getUserCountByRole(),
      ]).then((responses) {
        return {
          'total_users': responses[0] as int,
          'active_tasks': responses[1] as int,
          'system_score': responses[2] as int,
          'captains': (responses[3] as Map<String, int>)['captain'] ?? 0,
        };
      }),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'İstatistikler',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Toplam Kullanıcı',
                    (stats['total_users'] ?? 0).toString(),
                    Icons.people,
                    AppColors.primary,
                    onTap: () => _navigateToUsersList(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Aktif Görevler',
                    (stats['active_tasks'] ?? 0).toString(),
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
                    'Kaptanlar',
                    (stats['captains'] ?? 0).toString(),
                    Icons.star,
                    AppColors.warning,
                    onTap: () => _navigateToUsersList(context, initialTab: 2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Sistem Puanı',
                    (stats['system_score'] ?? 0).toString(),
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

  Widget _buildCaptainStatsSection(BuildContext context, String captainUid, AuthService authService, UserModel userData) {
    final userService = UserService();
    return FutureBuilder<Map<String, int>>(
      future: Future.wait([
        userService.getTeamMemberCount(captainUid),
        userService.getCompletedTasksThisMonth(captainUid),
        userService.getTotalScore(captainUid),
      ]).then((responses) {
        return {
          'team_members': responses[0],
          'completed_tasks_this_month': responses[1],
          'total_score': responses[2],
        };
      }),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final teamStats = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kaptan İstatistikleri',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Ekip Üyeleri',
                    (teamStats['team_members'] ?? 0).toString(),
                    Icons.people_alt,
                    AppColors.primary,
                    onTap: () => _navigateToMyTeam(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Bu Ay Tamamlanan \nGörevler',
                    (teamStats['completed_tasks_this_month'] ?? 0).toString(),
                    Icons.check_circle,
                    AppColors.error,
                    onTap: () => _navigateToTaskManagement(context, userData, initialTab: 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Toplam Puan',
              (teamStats['total_score'] ?? 0).toString(),
              Icons.score,
              AppColors.warning,
              onTap: () => _navigateToScoreTable(context, userData),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserStatsSection(BuildContext context, String userUid, AuthService authService, UserModel userData) {
    final userService = UserService();
    return FutureBuilder<Map<String, int>>(
      future: Future.wait([
        userService.getActiveTaskCount(userUid),
        userService.getCompletedTaskCount(userUid),
        userService.getTotalScore(userUid),
      ]).then((responses) {
        return {
          'active_tasks': responses[0],
          'completed_tasks': responses[1],
          'total_score': responses[2],
        };
      }),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final userStats = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Üye İstatistikleri',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Aktif Görevlerim',
                    (userStats['active_tasks'] ?? 0).toString(),
                    Icons.assignment,
                    AppColors.primary,
                    onTap: () => _navigateToTaskManagement(context, userData),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Yapılan Görevler',
                    (userStats['completed_tasks'] ?? 0).toString(),
                    Icons.check_circle_outline,
                    AppColors.error,
                    onTap: () => _navigateToTaskManagement(context, userData, initialTab: 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Toplam Puan',
              (userStats['total_score'] ?? 0).toString(),
              Icons.score,
              AppColors.warning,
              onTap: () => _navigateToScoreTable(context, userData),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivitiesSection(BuildContext context, String currentUserId) {
    final activityService = ActivityService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Son Aktiviteler',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
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
              return Center(child: Text('Aktivite yüklenirken hata oluştu: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Henüz bir aktivite bulunmamaktadır.'));
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
                  activity: activity,  // ← YENİ EKLENEN
                  isLastItem: index == activities.length - 1,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
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
        required ActivityModel activity,  // ← YENİ PARAMETRE
        bool isLastItem = false,
      }) {
    return GestureDetector(  // ← TAP EKLE (ÇOK ÖNEMLİ!)
      onTap: () => _showActivityDetails(context, activity),  // ← DIALOG AÇ
      child: Container(
        margin: EdgeInsets.only(bottom: isLastItem ? 0 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              time,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showActivityDetails(BuildContext context, ActivityModel activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: activity.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                activity.icon,
                color: activity.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatDetailedDateTime(activity.timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: activity.color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: activity.color.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  activity.subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tarih ve Saat',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatDetailedDateTime(activity.timestamp),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
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
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

// Zaman formatı (detaylı) metodu ekle:
  String _formatDetailedDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
}