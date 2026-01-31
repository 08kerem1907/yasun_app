import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/colors.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'admin_add_user_screen_fixed.dart';

class AdminManageUsersScreen extends StatefulWidget {
  const AdminManageUsersScreen({super.key});

  @override
  State<AdminManageUsersScreen> createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen> {
  final UserService _userService = UserService();
  UserModel? _currentUser;
  String _searchQuery = '';
  String _selectedRoleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      UserModel? user = await _userService.getUser(firebaseUser.uid);
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _navigateToAddUser() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminAddUserScreen(),
      ),
    );
    if (result == true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kullanıcı bilgisi yüklenene kadar bekle
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bool isAdmin = _currentUser?.isAdmin ?? false;

    return Scaffold(
      // FloatingActionButton - Daha görünür yaptık
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
        onPressed: _navigateToAddUser,
        icon: const Icon(Icons.person_add),
        label: const Text('Yeni Üye'),
        backgroundColor: AppColors.primary,
        elevation: 6,
      )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(isAdmin),
              _buildFilterBar(),
              Expanded(
                child: _buildUsersList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isAdmin) {
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
            child: Text(
              'Kullanıcıları Yönet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // AppBar'a da buton ekledik
          if (isAdmin)
            ElevatedButton.icon(
              onPressed: _navigateToAddUser,
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Yeni Üye'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Arama
          TextField(
            onChanged: (value) {
              setState(() => _searchQuery = value.toLowerCase());
            },
            decoration: InputDecoration(
              hintText: 'Kullanıcı ara...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Rol Filtresi
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tümü', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Yönetici', 'admin'),
                const SizedBox(width: 8),
                _buildFilterChip('Kaptan', 'captain'),
                const SizedBox(width: 8),
                _buildFilterChip('Kullanıcı', 'user'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedRoleFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedRoleFilter = value);
      },
      backgroundColor: Colors.transparent,
      selectedColor: AppColors.primary.withOpacity(0.2),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<List<UserModel>>(
      stream: _selectedRoleFilter == 'all'
          ? _userService.getAllUsers()
          : _userService.getUsersByRole(_selectedRoleFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Hata: ${snapshot.error}'),
              ],
            ),
          );
        }

        var users = snapshot.data ?? [];

        // Arama filtresi uygula
        if (_searchQuery.isNotEmpty) {
          users = users
              .where((user) =>
          user.displayName.toLowerCase().contains(_searchQuery) ||
              user.email.toLowerCase().contains(_searchQuery))
              .toList();
        }

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off,
                  size: 64,
                  color: Colors.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Arama sonucu bulunamadı'
                      : 'Kullanıcı bulunamadı',
                  style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                if (_searchQuery.isEmpty && _currentUser?.isAdmin == true)
                  ElevatedButton.icon(
                    onPressed: _navigateToAddUser,
                    icon: const Icon(Icons.person_add),
                    label: const Text('İlk Kullanıcıyı Ekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            return _buildUserCard(users[index]);
          },
        );
      },
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getRoleColor(user.role).withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getRoleIcon(user.role),
            color: _getRoleColor(user.role),
          ),
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user.email,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getRoleName(user.role),
                style: TextStyle(
                  fontSize: 10,
                  color: _getRoleColor(user.role),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              onPressed: () => _showEditUserDialog(user),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: () => _showDeleteConfirmation(user),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleName(String role) {
    switch (role) {
      case 'admin':
        return 'Yönetici';
      case 'captain':
        return 'Kaptan';
      case 'user':
        return 'Kullanıcı';
      default:
        return 'Bilinmiyor';
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'captain':
        return Icons.stars;
      case 'user':
        return Icons.person;
      default:
        return Icons.help_outline;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'captain':
        return Colors.orange;
      case 'user':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showEditUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => _EditUserDialog(
        user: user,
        userService: _userService,
      ),
    ).then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _showDeleteConfirmation(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Sil'),
        content: Text('${user.displayName} isimli kullanıcıyı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _userService.deleteUser(user.uid);
                setState(() {});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kullanıcı başarıyla silindi'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _EditUserDialog extends StatefulWidget {
  final UserModel user;
  final UserService userService;

  const _EditUserDialog({
    required this.user,
    required this.userService,
  });

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  late TextEditingController _nameController;
  late String _selectedRole;
  String? _selectedCaptainId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _selectedRole = widget.user.role;
    _selectedCaptainId = widget.user.captainId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kullanıcıyı Düzenle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ad Soyad
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

            // Rol Seçimi
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Rol',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.admin_panel_settings),
              ),
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('Yönetici')),
                DropdownMenuItem(value: 'captain', child: Text('Kaptan')),
                DropdownMenuItem(value: 'user', child: Text('Kullanıcı')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRole = value ?? 'user';
                  if (value == 'admin' || value == 'captain') {
                    _selectedCaptainId = null;
                  }
                });
              },
            ),

            // Kaptan Seçimi (sadece user rolü için)
            if (_selectedRole == 'user') ...[
              const SizedBox(height: 16),
              StreamBuilder<List<UserModel>>(
                stream: widget.userService.getUsersByRole('captain'),
                builder: (context, snapshot) {
                  final captains = snapshot.data ?? [];

                  if (captains.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.warning),
                      ),
                      child: const Text(
                        'Henüz kaptan bulunmamaktadır',
                        style: TextStyle(fontSize: 12, color: AppColors.warning),
                      ),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedCaptainId,
                    decoration: const InputDecoration(
                      labelText: 'Bağlı Kaptan',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group),
                    ),
                    hint: const Text('Kaptan Seçin (Opsiyonel)'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Kaptansız', style: TextStyle(fontStyle: FontStyle.italic)),
                      ),
                      ...captains.map<DropdownMenuItem<String>>((captain) {
                        return DropdownMenuItem<String>(
                          value: captain.uid,
                          child: Text(captain.displayName),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedCaptainId = value);
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: _isLoading
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : const Text('Kaydet', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      // İsim değişikliği
      if (_nameController.text != widget.user.displayName) {
        await widget.userService.updateUserDisplayName(
          widget.user.uid,
          _nameController.text,
        );
      }

      // Rol değişikliği
      if (_selectedRole != widget.user.role) {
        await widget.userService.updateUserRole(widget.user.uid, _selectedRole);

        // Eğer kaptana dönüştürülüyorsa teamId'yi uid yap
        if (_selectedRole == 'captain') {
          await widget.userService.updateUserTeam(widget.user.uid, widget.user.uid);
          await widget.userService.updateUserCaptain(widget.user.uid, null);
        }
      }

      // Kaptan değişikliği (sadece user için)
      if (_selectedRole == 'user' && _selectedCaptainId != widget.user.captainId) {
        await widget.userService.updateUserCaptain(widget.user.uid, _selectedCaptainId);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı başarıyla güncellendi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
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
}
