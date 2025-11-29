import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../models/user_model.dart';
import '../services/auth_service_fixed.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  bool _isEditing = false;
  final _displayNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

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
        _displayNameController.text = userData.displayName;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(context, userData, authService),
                    const SizedBox(height: 24),
                    _buildProfileCard(userData),
                    const SizedBox(height: 16),
                    _buildStatsCard(userData),
                    const SizedBox(height: 16),
                    _buildSettingsCard(context, authService),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, UserModel userData, AuthService authService) {
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
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Profil',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.logout, color: AppColors.error),
                onPressed: () => _showLogoutDialog(context, authService),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Text(
                userData.displayName.isNotEmpty
                    ? userData.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Ad Soyad
          Text(
            userData.displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          // Email
          Text(
            userData.email,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          // Rol Badge
          _buildRoleBadge(userData.role),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    IconData icon;
    String label;

    switch (role) {
      case 'admin':
        color = AppColors.error;
        icon = Icons.admin_panel_settings;
        label = 'Yönetici';
        break;
      case 'captain':
        color = AppColors.warning;
        icon = Icons.star;
        label = 'Kaptan';
        break;
      case 'user':
        color = AppColors.success;
        icon = Icons.person;
        label = 'Kullanıcı';
        break;
      default:
        color = AppColors.textSecondary;
        icon = Icons.help;
        label = 'Bilinmeyen';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(UserModel userData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
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
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Kişisel Bilgiler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _isEditing ? Icons.close : Icons.edit_square,
                    color: _isEditing ? AppColors.error : AppColors.primary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isEditing = !_isEditing;
                      if (!_isEditing) {
                        _displayNameController.text = userData.displayName;
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _isEditing
                ? _buildEditForm(userData)
                : _buildInfoList(userData),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoList(UserModel userData) {
    return Column(
      children: [
        _buildInfoRow(
          icon: Icons.account_circle_rounded,
          label: 'Ad Soyad',
          value: userData.displayName,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          icon: Icons.alternate_email_rounded,
          label: 'Email',
          value: userData.email,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          icon: Icons.workspace_premium_rounded,
          label: 'Rol',
          value: userData.roleDisplayName,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          icon: Icons.event_available_rounded,
          label: 'Kayıt Tarihi',
          value: DateFormat('dd.MM.yyyy').format(userData.createdAt),
        ),
        if (userData.lastLogin != null) ...[
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.access_time,
            label: 'Son Giriş',
            value: DateFormat('dd.MM.yyyy HH:mm').format(userData.lastLogin!),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
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
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm(UserModel userData) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _displayNameController,
            decoration: InputDecoration(
              labelText: 'Ad Soyad',
              hintText: 'Adınızı ve soyadınızı girin',
              prefixIcon: const Icon(Icons.person, color: AppColors.primary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderFocused, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ad soyad gerekli';
              }
              if (value.length < 3) {
                return 'Ad soyad en az 3 karakter olmalı';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => _saveChanges(userData),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Değişiklikleri Kaydet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(UserModel userData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'İstatistiklerim',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<Map<String, int>>(
            future: Future.wait([
              _userService.getActiveTaskCount(userData.uid),
              _userService.getCompletedTaskCount(userData.uid),
              _userService.getTotalScore(userData.uid),
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

              final stats = snapshot.data!;

              return Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      label: 'Aktif Görevler',
                      value: (stats['active_tasks'] ?? 0).toString(),
                      icon: Icons.assignment_turned_in_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      label: 'Tamamlanan',
                      value: (stats['completed_tasks'] ?? 0).toString(),
                      icon: Icons.task_alt_rounded,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      label: 'Toplam Puan',
                      value: (stats['total_score'] ?? 0).toString(),
                      icon: Icons.emoji_events_rounded,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
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
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
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
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSettingsCard(BuildContext context, AuthService authService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
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
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ayarlar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const Divider(height: 1),

          _buildSettingItem(
            icon: Icons.notifications,
            title: 'Bildirimler',
            subtitle: 'Bildirim tercihlerinizi yönetin',
            onTap: () => _showNotificationSettings(context),
          ),
          _buildSettingItem(
            icon: Icons.help,
            title: 'Yardım & Destek',
            subtitle: 'SSS ve destek talebi',
            onTap: () => _showHelpAndSupport(context),
          ),
          _buildSettingItem(
            icon: Icons.info,
            title: 'Uygulama Hakkında',
            subtitle: 'Versiyon 1.0.1',
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Future<void> _saveChanges(UserModel userData) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _userService.updateUserDisplayName(
        userData.uid,
        _displayNameController.text.trim(),
      );

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Değişiklikler kaydedildi'),
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
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.error),
            SizedBox(width: 12),
            Text('Çıkış Yap'),
          ],
        ),
        content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    // Bildirim ayarları için state'ler
    bool pushNotifications = true;
    bool emailNotifications = true;
    bool taskNotifications = true;
    bool teamNotifications = true;
    bool scoreNotifications = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.notifications_active, color: AppColors.primary),
              SizedBox(width: 12),
              Text('Bildirim Ayarları'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Almak istediğiniz bildirimleri seçin',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                _buildNotificationSwitch(
                  title: 'Push Bildirimleri',
                  subtitle: 'Uygulama bildirimleri',
                  value: pushNotifications,
                  icon: Icons.notifications,
                  onChanged: (value) {
                    setState(() => pushNotifications = value);
                  },
                ),
                const Divider(height: 32),
                _buildNotificationSwitch(
                  title: 'Email Bildirimleri',
                  subtitle: 'Email ile bildirim al',
                  value: emailNotifications,
                  icon: Icons.email,
                  onChanged: (value) {
                    setState(() => emailNotifications = value);
                  },
                ),
                const Divider(height: 32),
                _buildNotificationSwitch(
                  title: 'Görev Bildirimleri',
                  subtitle: 'Yeni görev atandığında',
                  value: taskNotifications,
                  icon: Icons.assignment,
                  onChanged: (value) {
                    setState(() => taskNotifications = value);
                  },
                ),
                const Divider(height: 32),
                _buildNotificationSwitch(
                  title: 'Takım Bildirimleri',
                  subtitle: 'Takım aktiviteleri',
                  value: teamNotifications,
                  icon: Icons.people,
                  onChanged: (value) {
                    setState(() => teamNotifications = value);
                  },
                ),
                const Divider(height: 32),
                _buildNotificationSwitch(
                  title: 'Puan Bildirimleri',
                  subtitle: 'Puan değişikliklerinde',
                  value: scoreNotifications,
                  icon: Icons.score,
                  onChanged: (value) {
                    setState(() => scoreNotifications = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bildirim ayarları kaydedildi'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  void _showHelpAndSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
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
                    const Icon(Icons.help_center, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Yardım & Destek',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SSS Başlığı
                      const Text(
                        'Sık Sorulan Sorular',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // SSS Listesi
                      _buildFAQItem(
                        question: 'Nasıl görev oluştururum?',
                        answer: 'Ana sayfada "Görev Yönetimi" sekmesine giderek yeni görev oluşturabilirsiniz. Admin ve Captain yetkilerine sahip kullanıcılar görev atayabilir.',
                      ),
                      const SizedBox(height: 12),
                      _buildFAQItem(
                        question: 'Takımıma nasıl üye eklerim?',
                        answer: 'Captain yetkisine sahipseniz, "Ekibim" sekmesinden takımınıza üye ekleyebilirsiniz. Sağ alt köşedeki "+" butonuna tıklayın.',
                      ),
                      const SizedBox(height: 12),
                      _buildFAQItem(
                        question: 'Puan sistemi nasıl çalışır?',
                        answer: 'Her tamamlanan görev için puan kazanırsınız. Puanlarınız profil sayfanızda görüntülenir ve puan tablosunda sıralanırsınız.',
                      ),
                      const SizedBox(height: 12),
                      _buildFAQItem(
                        question: 'Bildirimlerimi nasıl yönetirim?',
                        answer: 'Profil sayfasında "Ayarlar" bölümünden "Bildirimler" seçeneğine tıklayarak bildirim tercihlerinizi özelleştirebilirsiniz.',
                      ),
                      const SizedBox(height: 12),
                      _buildFAQItem(
                        question: 'Şifremi nasıl değiştirim?',
                        answer: 'Güvenlik nedeniyle şifre değişikliği email üzerinden yapılmaktadır. Giriş ekranında "Şifremi Unuttum" seçeneğini kullanın.',
                      ),

                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),

                      // İletişim Bilgileri
                      const Text(
                        'Destek Talebi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          const Icon(Icons.email, color: Colors.grey),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Email',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'destek@takimyonetim.com',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),


                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.help_outline,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final feedbackController = TextEditingController();
    String selectedCategory = 'Genel';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.feedback, color: AppColors.primary),
              SizedBox(width: 12),
              Text('Geri Bildirim'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Görüşleriniz bizim için çok değerli!',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Kategori Seçimi
                const Text(
                  'Kategori',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: ['Genel', 'Hata Bildirimi', 'Öneri', 'Diğer']
                      .map((category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedCategory = value!);
                  },
                ),
                const SizedBox(height: 16),

                // Mesaj
                const Text(
                  'Mesajınız',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: feedbackController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Geri bildiriminizi buraya yazın...',
                    hintStyle: const TextStyle(color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.borderFocused,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                feedbackController.dispose();
                Navigator.pop(context);
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (feedbackController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen bir mesaj yazın'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                feedbackController.dispose();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Geri bildiriminiz gönderildi. Teşekkürler!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('Gönder'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Uygulama Hakkında'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Takım Yönetim Sistemi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Versiyon: 1.0.1',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Takımınızı kolayca yönetebileceğiniz, görev atayabileceğiniz ve performans takibi yapabileceğiniz modern bir uygulama.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
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
}