import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class MyTeamScreen extends StatefulWidget {
  const MyTeamScreen({super.key});

  @override
  State<MyTeamScreen> createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends State<MyTeamScreen> {
  final UserService _userService = UserService();
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Kullanıcı bulunamadı')),
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

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text('Kullanıcı verileri yüklenemedi')),
          );
        }

        final userData = snapshot.data!;

        // Sadece captain'lar bu ekranı görebilir
        if (!userData.isCaptain) {
          return _buildNoPermission();
        }

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(context, userData),
                  _buildTeamStats(userData),
                  _buildFilterChips(),
                  Expanded(
                    child: _buildTeamMembersList(userData),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddMemberDialog(userData),
            icon: const Icon(Icons.person_add),
            label: const Text('Üye Ekle'),
            backgroundColor: AppColors.primary,
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, UserModel userData) {
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
              Icons.people_alt,
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
                  'Ekibim',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Kaptan: ${userData.displayName}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textSecondary),
            onPressed: () {
              // Arama fonksiyonu
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStats(UserModel userData) {
    return Container(
      margin: const EdgeInsets.all(24),
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
      padding: const EdgeInsets.all(20),
      child: FutureBuilder<Map<String, int>>(
        future: Future.wait([
          _userService.getTeamMemberCount(userData.uid),
          _userService.getCompletedTasksThisMonth(userData.uid),
          _userService.getTotalScore(userData.uid),
        ]).then((responses) {
          return {
            'team_members': responses[0],
            'completed_tasks': responses[1],
            'total_score': responses[2],
          };
        }),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final stats = snapshot.data!;

          return Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: 'Ekip Üyeleri',
                  value: (stats['team_members'] ?? 0).toString(),
                  icon: Icons.people,
                  color: AppColors.primary,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: AppColors.border,
              ),
              Expanded(
                child: _buildStatItem(
                  label: 'Bu Ay\nTamamlanan',
                  value: (stats['completed_tasks'] ?? 0).toString(),
                  icon: Icons.check_circle,
                  color: AppColors.success,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: AppColors.border,
              ),
              Expanded(
                child: _buildStatItem(
                  label: 'Toplam Puan',
                  value: (stats['total_score'] ?? 0).toString(),
                  icon: Icons.score,
                  color: AppColors.warning,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Tümü', 'all', Icons.people),
            const SizedBox(width: 8),
            _buildFilterChip('Aktif Üyeler', 'active', Icons.check_circle),
            const SizedBox(width: 8),
            _buildFilterChip('En Yüksek Puan', 'top_score', Icons.star),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }

  Widget _buildTeamMembersList(UserModel userData) {
    return StreamBuilder<List<UserModel>>(
      stream: _userService.getTeamMembers(userData.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Hata: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        var members = snapshot.data!;

        // Filtreleme
        if (_selectedFilter == 'active') {
          members = members.where((m) => m.lastLogin != null).toList();
        } else if (_selectedFilter == 'top_score') {
          // Puana göre sıralama yapılabilir (şimdilik sadece filtre)
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: members.length,
          itemBuilder: (context, index) {
            return _buildMemberCard(members[index], userData);
          },
        );
      },
    );
  }

  Widget _buildMemberCard(UserModel member, UserModel captain) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showMemberDetailsDialog(member),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      member.displayName.isNotEmpty
                          ? member.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Member Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildMemberBadge(member),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            member.lastLogin != null
                                ? _formatDate(member.lastLogin!)
                                : 'Hiç giriş yapmadı',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Stats & Actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FutureBuilder<int>(
                      future: _userService.getTotalScore(member.uid),
                      builder: (context, snapshot) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.score,
                                size: 14,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (snapshot.data ?? 0).toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => _showMemberOptionsMenu(member, captain),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberBadge(UserModel member) {
    Color color = AppColors.success;
    IconData icon = Icons.person;
    String label = 'Üye';

    if (member.role == 'captain') {
      color = AppColors.warning;
      icon = Icons.star;
      label = 'Kaptan';
    } else if (member.role == 'admin') {
      color = AppColors.error;
      icon = Icons.admin_panel_settings;
      label = 'Yönetici';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Az önce';
        }
        return '${difference.inMinutes} dk önce';
      }
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return DateFormat('dd.MM.yyyy').format(date);
    }
  }

  void _showMemberDetailsDialog(UserModel member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  member.displayName.isNotEmpty
                      ? member.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Üye Detayları'),
            ),
          ],
        ),
        content: FutureBuilder<Map<String, int>>(
          future: Future.wait([
            _userService.getActiveTaskCount(member.uid),
            _userService.getCompletedTaskCount(member.uid),
            _userService.getTotalScore(member.uid),
          ]).then((responses) {
            return {
              'active_tasks': responses[0],
              'completed_tasks': responses[1],
              'total_score': responses[2],
            };
          }),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final stats = snapshot.data!;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Ad Soyad', member.displayName),
                const SizedBox(height: 12),
                _buildDetailRow('Email', member.email),
                const SizedBox(height: 12),
                _buildDetailRow('Rol', member.roleDisplayName),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Kayıt Tarihi',
                  DateFormat('dd.MM.yyyy').format(member.createdAt),
                ),
                if (member.lastLogin != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Son Giriş',
                    DateFormat('dd.MM.yyyy HH:mm').format(member.lastLogin!),
                  ),
                ],
                const Divider(height: 32),
                const Text(
                  'İstatistikler',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Aktif Görevler',
                  (stats['active_tasks'] ?? 0).toString(),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Tamamlanan Görevler',
                  (stats['completed_tasks'] ?? 0).toString(),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Toplam Puan',
                  (stats['total_score'] ?? 0).toString(),
                ),
              ],
            );
          },
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

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showMemberOptionsMenu(UserModel member, UserModel captain) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.assignment, color: AppColors.primary),
              title: const Text('Görev Ata'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Görev atama özelliği yakında eklenecek'),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: AppColors.primary),
              title: const Text('Mesaj Gönder'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mesajlaşma özelliği yakında eklenecek'),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_remove, color: AppColors.error),
              title: const Text('Takımdan Çıkar'),
              onTap: () {
                Navigator.pop(context);
                _showRemoveMemberDialog(member);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveMemberDialog(UserModel member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Üyeyi Çıkar'),
        content: Text(
          '${member.displayName} üyesini takımdan çıkarmak istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _userService.updateUserTeam(member.uid, null);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${member.displayName} takımdan çıkarıldı'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Çıkar'),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(UserModel captain) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_add, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Ekibe Üye Ekle',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: _buildAvailableUsersList(captain),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableUsersList(UserModel captain) {
    return StreamBuilder<List<UserModel>>(
      stream: _userService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Hata: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('Kullanıcı bulunamadı'),
          );
        }

        // Takıma eklenmemiş ve captain/admin olmayan kullanıcıları filtrele
        final availableUsers = snapshot.data!.where((user) {
          return user.teamId == null &&
              user.role == 'user' &&
              user.uid != captain.uid;
        }).toList();

        if (availableUsers.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      size: 48,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Eklenebilecek Üye Yok',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tüm kullanıcılar bir takıma atanmış\nveya yetkili pozisyonlarda',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: availableUsers.length,
          itemBuilder: (context, index) {
            return _buildAvailableUserCard(availableUsers[index], captain);
          },
        );
      },
    );
  }

  Widget _buildAvailableUserCard(UserModel user, UserModel captain) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              user.displayName.isNotEmpty
                  ? user.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user.email,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<int>(
              future: _userService.getTotalScore(user.uid),
              builder: (context, snapshot) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.score,
                        size: 12,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Puan: ${snapshot.data ?? 0}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _addMemberToTeam(user, captain),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Ekle',
            style: TextStyle(fontSize: 13),
          ),
        ),
      ),
    );
  }

  Future<void> _addMemberToTeam(UserModel user, UserModel captain) async {
    try {
      // Kullanıcının teamId'sini captain'ın uid'si ile güncelle
      await _userService.updateUserTeam(user.uid, captain.uid);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.displayName} ekibe eklendi!'),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'Geri Al',
              textColor: Colors.white,
              onPressed: () async {
                await _userService.updateUserTeam(user.uid, null);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Kullanıcı bulunamadı'));
    }

    return StreamBuilder<UserModel?>(
      stream: authService.getUserDataStream(currentUser.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data!;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_outline,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Henüz Ekip Üyesi Yok',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ekibinize üye ekleyerek başlayın',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showAddMemberDialog(userData),
                icon: const Icon(Icons.person_add),
                label: const Text('Üye Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoPermission() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Yetkiniz Yok',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bu sayfayı görüntülemek için\nkaptan yetkisine sahip olmalısınız',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}