import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  final UserService _userService = UserService();
  String _selectedFilter = 'all';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildFilterChips(),
              Expanded(
                child: StreamBuilder<UserModel?>(
                  stream: authService.getUserDataStream(currentUser!.uid),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final currentUserData = userSnapshot.data!;

                    // Sadece admin ve captain'lar rol yönetimi yapabilir
                    if (!currentUserData.isAdmin) {
                      return _buildNoPermission();
                    }

                    return _buildUsersList(currentUserData);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rol Yönetimi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kullanıcı rollerini düzenle',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'Tümü', Icons.people),
            const SizedBox(width: 8),
            _buildFilterChip('admin', 'Yöneticiler', Icons.admin_panel_settings),
            const SizedBox(width: 8),
            _buildFilterChip('captain', 'Kaptanlar', Icons.star),
            const SizedBox(width: 8),
            _buildFilterChip('user', 'Kullanıcılar', Icons.person),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    Color color;

    switch (value) {
      case 'admin':
        color = AppColors.error;
        break;
      case 'captain':
        color = AppColors.warning;
        break;
      case 'user':
        color = AppColors.success;
        break;
      default:
        color = AppColors.primary;
    }

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : color,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor: Colors.white,
      selectedColor: color,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: isSelected ? color : AppColors.border,
        width: isSelected ? 2 : 1,
      ),
    );
  }

  Widget _buildUsersList(UserModel currentUserData) {
    Stream<List<UserModel>> usersStream;

    if (_selectedFilter == 'all') {
      usersStream = _userService.getAllUsers();
    } else {
      usersStream = _userService.getUsersByRole(_selectedFilter);
    }

    return StreamBuilder<List<UserModel>>(
      stream: usersStream,
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

        final users = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            // Kendi hesabını düzenlemeyi engelle
            final isSelf = user.uid == currentUserData.uid;
            return _buildUserCard(user, currentUserData, isSelf);
          },
        );
      },
    );
  }

  Widget _buildUserCard(UserModel user, UserModel currentUserData, bool isSelf) {
    Color roleColor;
    IconData roleIcon;

    switch (user.role) {
      case 'admin':
        roleColor = AppColors.error;
        roleIcon = Icons.admin_panel_settings;
        break;
      case 'captain':
        roleColor = AppColors.warning;
        roleIcon = Icons.star;
        break;
      default:
        roleColor = AppColors.success;
        roleIcon = Icons.person;
    }

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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: roleColor.withOpacity(0.1),
          child: Icon(roleIcon, color: roleColor, size: 28),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelf)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Siz',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user.email,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(roleIcon, size: 14, color: roleColor),
                  const SizedBox(width: 6),
                  Text(
                    user.roleDisplayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: roleColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: isSelf
            ? null
            : IconButton(
          icon: const Icon(Icons.edit, color: AppColors.primary),
          onPressed: () => _showRoleChangeDialog(user, currentUserData),
        ),
      ),
    );
  }

  void _showRoleChangeDialog(UserModel user, UserModel currentUserData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Rol Değiştir'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${user.displayName} için yeni rol seçin:',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            _buildRoleOption(user, 'admin', 'Yönetici', Icons.admin_panel_settings, AppColors.error, currentUserData),
            const SizedBox(height: 12),
            _buildRoleOption(user, 'captain', 'Kaptan', Icons.star, AppColors.warning, currentUserData),
            const SizedBox(height: 12),
            _buildRoleOption(user, 'user', 'Kullanıcı', Icons.person, AppColors.success, currentUserData),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOption(
      UserModel user,
      String role,
      String label,
      IconData icon,
      Color color,
      UserModel currentUserData,
      ) {
    final isCurrentRole = user.role == role;

    return InkWell(
      onTap: isCurrentRole ? null : () => _changeUserRole(user, role),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentRole ? color.withOpacity(0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentRole ? color : AppColors.border,
            width: isCurrentRole ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isCurrentRole ? FontWeight.w600 : FontWeight.normal,
                  color: isCurrentRole ? color : AppColors.textPrimary,
                ),
              ),
            ),
            if (isCurrentRole)
              Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _changeUserRole(UserModel user, String newRole) async {
    Navigator.pop(context); // Dialog'u kapat

    setState(() => _isLoading = true);

    try {
      await _userService.updateUserRole(user.uid, newRole);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.displayName} rolü başarıyla güncellendi!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rol güncellenirken hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildEmptyState() {
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
            'Kullanıcı Bulunamadı',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bu filtrede hiç kullanıcı yok',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPermission() {
    return Center(
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
            'Rol yönetimi için yönetici veya kaptan\nyetkisine sahip olmalısınız',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
