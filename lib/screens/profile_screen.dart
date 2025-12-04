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
      return Scaffold(
        body: Center(
          child: Text(
            'Kullanıcı bulunamadı',
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
        ),
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
          return Scaffold(
            body: Center(
              child: Text(
                'Kullanıcı verileri yüklenemedi',
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
            ),
          );
        }

        final userData = snapshot.data!;
        _displayNameController.text = userData.displayName;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
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
    final cardColor = Theme.of(context).cardColor;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
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
              Text(
                'Profil',
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),

              const Spacer(),
              IconButton(
                icon: const Icon(Icons.logout, color: AppColors.error),
                onPressed: () => _showLogoutDialog(context, authService),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
                userData.displayName.isNotEmpty ? userData.displayName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userData.displayName,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),
          Text(
            userData.email,
            style: textTheme.bodyMedium,
          ),

          const SizedBox(height: 12),
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
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildProfileCard(UserModel userData) {
    final cardColor = Theme.of(context).cardColor;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: cardColor,
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
                Text(
                  'Kişisel Bilgiler',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),

                const Spacer(),
                IconButton(
                  icon: Icon(_isEditing ? Icons.close : Icons.edit_square, color: _isEditing ? AppColors.error : AppColors.primary),
                  onPressed: () {
                    setState(() {
                      _isEditing = !_isEditing;
                      if (!_isEditing) _displayNameController.text = userData.displayName;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _isEditing ? _buildEditForm(userData) : _buildInfoList(userData),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoList(UserModel userData) {
    return Column(
      children: [
        _buildInfoRow(icon: Icons.account_circle_rounded, label: 'Ad Soyad', value: userData.displayName),
        const SizedBox(height: 16),
        _buildInfoRow(icon: Icons.alternate_email_rounded, label: 'Email', value: userData.email),
        const SizedBox(height: 16),
        _buildInfoRow(icon: Icons.workspace_premium_rounded, label: 'Rol', value: userData.roleDisplayName),
        const SizedBox(height: 16),
        _buildInfoRow(icon: Icons.event_available_rounded, label: 'Kayıt Tarihi', value: DateFormat('dd.MM.yyyy').format(userData.createdAt)),
        if (userData.lastLogin != null) ...[
          const SizedBox(height: 16),
          _buildInfoRow(icon: Icons.access_time, label: 'Son Giriş', value: DateFormat('dd.MM.yyyy HH:mm').format(userData.lastLogin!)),
        ],
      ],
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    final textTheme = Theme.of(context).textTheme;
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
              Text(label, style: textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(value, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        )

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
              fillColor: Theme.of(context).inputDecorationTheme.fillColor,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ad soyad gerekli';
              if (value.length < 3) return 'Ad soyad en az 3 karakter olmalı';
              return null;
            },
          ),
          const SizedBox(height: 20),
          Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () => _saveChanges(userData),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Değişiklikleri Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(UserModel userData) {
    final cardColor = Theme.of(context).cardColor;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İstatistiklerim',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),
          FutureBuilder<Map<String, int>>(
            future: Future.wait([
              _userService.getActiveTaskCount(userData.uid),
              _userService.getCompletedTaskCount(userData.uid),
              _userService.getTotalScore(userData.uid),
            ]).then((responses) => {
              'active_tasks': responses[0],
              'completed_tasks': responses[1],
              'total_score': responses[2],
            }),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final stats = snapshot.data!;
              return Row(
                children: [
                  Expanded(child: _buildStatItem(label: 'Aktif Görevler', value: (stats['active_tasks'] ?? 0).toString(), icon: Icons.assignment_turned_in_rounded, color: AppColors.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatItem(label: 'Tamamlanan', value: (stats['completed_tasks'] ?? 0).toString(), icon: Icons.task_alt_rounded, color: AppColors.success)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatItem(label: 'Toplam Puan', value: (stats['total_score'] ?? 0).toString(), icon: Icons.emoji_events_rounded, color: AppColors.warning)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required String label, required String value, required IconData icon, required Color color}) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),

      ],
    );
  }

  Widget _buildSettingsCard(BuildContext context, AuthService authService) {
    final cardColor = Theme.of(context).cardColor;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ayarlar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),

            ),
          ),
          const Divider(height: 1),
          _buildSettingItem(icon: Icons.help, title: 'Yardım & Destek', subtitle: 'SSS ve destek talebi', onTap: () => _showHelpAndSupport(context)),
          _buildSettingItem(icon: Icons.info, title: 'Uygulama Hakkında', subtitle: 'Versiyon 1.0.1', onTap: () => _showAboutDialog(context)),
        ],
      ),
    );
  }

  Widget _buildSettingItem({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Theme.of(context).textTheme.bodySmall?.color,
      ),
      onTap: onTap,

    );
  }

  Future<void> _saveChanges(UserModel userData) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _userService.updateUserDisplayName(userData.uid, _displayNameController.text.trim());
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Değişiklikler kaydedildi'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: const [Icon(Icons.logout, color: AppColors.error), SizedBox(width: 12), Text('Çıkış Yap')]),
        content: const Text('Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () async { await authService.signOut(); if (mounted) Navigator.pop(context); }, child: const Text('Çıkış Yap', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
  }

  void _showHelpAndSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Yardım & Destek'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildFAQItem('SSS 1', 'SSS cevabı 1'),
              _buildFAQItem('SSS 2', 'SSS cevabı 2'),
              _buildFAQItem('SSS 3', 'SSS cevabı 3'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat', style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: [Padding(padding: const EdgeInsets.all(8.0), child: Text(answer))],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Uygulama Adı',
      applicationVersion: '1.0.1',
      applicationLegalese: '© 2025 Furkan Toptan',
      children: [const SizedBox(height: 8), const Text('Bu uygulama kullanıcı profili ve istatistik yönetimi için geliştirilmiştir.')],
    );
  }
}
