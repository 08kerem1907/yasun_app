import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'users_list_screen.dart';
import 'add_user_screen.dart';
import 'role_management_screen.dart';

class HomeScreenContent extends StatelessWidget {
  final String role;
  const HomeScreenContent({super.key, required this.role});

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
                        if (userData.isAdmin) _buildAdminStatsSection(context, authService),
                        if (userData.isCaptain) _buildCaptainStatsSection(context, userData.uid, authService),
                        if (userData.isUser) _buildUserStatsSection(context, userData.uid, authService),
                        const SizedBox(height: 32),
                        _buildRecentActivitiesSection(context),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Takım Yönetim Sistemi',
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

  Widget _buildAdminStatsSection(BuildContext context, AuthService authService) {
    final userService = UserService();

    return FutureBuilder<Map<String, dynamic>>(
      future: Future.wait([
        userService.getUserCount(), // Toplam kullanıcı sayısını direkt al
        userService.getActiveTaskCount(authService.currentUser!.uid),
        userService.getSystemScore(),
        userService.getUserCountByRole(), // Rol bazlı sayıları da al
      ]).then((responses) {
        return {
          'total_users': responses[0] as int, // Toplam kullanıcı
          'active_tasks': responses[1] as int,
          'system_score': responses[2] as int,
          'captains': (responses[3] as Map<String, int>)['captain'] ?? 0, // Kaptan sayısı
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
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Aktif Görevler',
                    (stats['active_tasks'] ?? 0).toString(),
                    Icons.task,
                    AppColors.error,
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
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Sistem Puanı',
                    (stats['system_score'] ?? 0).toString(),
                    Icons.score,
                    AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCaptainStatsSection(BuildContext context, String captainUid, AuthService authService) {
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
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Bu Ay Tamamlanan \nGörevler',
                    (teamStats['completed_tasks_this_month'] ?? 0).toString(),
                    Icons.check_circle,
                    AppColors.error,
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
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserStatsSection(BuildContext context, String userUid, AuthService authService) {
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
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Yapılan Görevler',
                    (userStats['completed_tasks'] ?? 0).toString(),
                    Icons.check_circle_outline,
                    AppColors.error,
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
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivitiesSection(BuildContext context) {
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
        _buildActivityItem(
          context,
          icon: Icons.assignment_turned_in,
          title: 'Yeni Görev Atandı',
          subtitle: '"Ana sayfa düzenlemesi" görevi size atandı.',
          time: '10 dakika önce',
        ),
        _buildActivityItem(
          context,
          icon: Icons.score,
          title: 'Puan Güncellendi',
          subtitle: 'Yeni puanınız: 1250',
          time: '1 saat önce',
        ),
        _buildActivityItem(
          context,
          icon: Icons.group_add,
          title: 'Takıma Yeni Üye',
          subtitle: 'Ahmet Yılmaz takıma katıldı.',
          time: '3 saat önce',
          isLastItem: true,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
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
    );
  }

  Widget _buildActivityItem(BuildContext context, {required IconData icon, required String title, required String subtitle, required String time, bool isLastItem = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isLastItem ? 0 : 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
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
    );
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