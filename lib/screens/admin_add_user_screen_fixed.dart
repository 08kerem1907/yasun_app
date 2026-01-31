import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/colors.dart';
import '../services/auth_service_fixed.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class AdminAddUserScreen extends StatefulWidget {
  const AdminAddUserScreen({super.key});

  @override
  State<AdminAddUserScreen> createState() => _AdminAddUserScreenState();
}

class _AdminAddUserScreenState extends State<AdminAddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  String _selectedRole = 'user';
  String? _selectedCaptainId;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureAdminPassword = true;

  final UserService _userService = UserService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleAddUser() async {
    if (!_formKey.currentState!.validate()) return;

    // Admin şifresi zorunlu
    if (_adminPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Oturum açmanız için şifre gerekmektedir'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }


    setState(() => _isLoading = true);

    try {
      // Mevcut admin bilgileri
      final currentAdmin = FirebaseAuth.instance.currentUser;
      final adminEmail = currentAdmin?.email;

      final authService = Provider.of<AuthService>(context, listen: false);

      // Rol bazlı teamId ve captainId ayarı
      String? finalTeamId;
      String? finalCaptainId;

      if (_selectedRole == 'captain') {
        finalTeamId = null;
        finalCaptainId = null;
      } else if (_selectedRole == 'user') {
        finalTeamId = null;
        finalCaptainId = _selectedCaptainId;
      } else {
        finalTeamId = null;
        finalCaptainId = null;
      }

      // Yeni kullanıcıyı oluştur ve admin oturumunu koru
      await authService.signUpWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim(),
        role: _selectedRole,
        teamId: finalTeamId,
        captainId: finalCaptainId,
        keepAdminSession: true,
        adminEmail: adminEmail,
        adminPassword: _adminPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı başarıyla oluşturuldu!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Hata: ${e.toString()}';

        // Hata mesajını daha okunabilir yap
        if (e.toString().contains('wrong-password')) {
          errorMessage = 'Hata: Yönetici şifresi yanlış!';
        } else if (e.toString().contains('user-not-found')) {
          errorMessage = 'Hata: Yönetici hesabı bulunamadı!';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.darkBackground,
              AppColors.darkBackground.withOpacity(0.8),
            ],
          )
              : AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, isDark),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildForm(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
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
          IconButton(
            icon: Icon(Icons.arrow_back,
                color: isDark ? AppColors.darkTextPrimary : AppColors
                    .textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Yeni Kullanıcı Ekle',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors
                    .textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_add,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Kullanıcı Bilgileri',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors
                        .textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Yeni kullanıcı eklemek için aşağıdaki bilgileri doldurun',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors
                    .textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            _buildTextField(
              isDark: isDark,
              controller: _displayNameController,
              label: 'Ad Soyad',
              hint: 'Örn: Ahmet Yılmaz',
              icon: Icons.person,
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

            _buildTextField(
              isDark: isDark,
              controller: _emailController,
              label: 'Email Adresi',
              hint: 'ornek@example.com',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email adresi gerekli';
                }
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Geçerli bir email adresi girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            _buildTextField(
              isDark: isDark,
              controller: _passwordController,
              label: 'Şifre',
              hint: 'En az 6 karakter',
              icon: Icons.lock,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: isDark ? AppColors.darkTextSecondary : AppColors
                      .textSecondary,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Şifre gerekli';
                }
                if (value.length < 6) {
                  return 'Şifre en az 6 karakter olmalı';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            _buildRoleSelector(isDark),


            const Divider(height: 48),

            Row(
              children: [
                Icon(
                  Icons.security,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Yönetici Onayı',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors
                        .textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'İşlemi tamamlamak için kendi şifrenizi girin',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors
                    .textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            _buildTextField(
              isDark: isDark,
              controller: _adminPasswordController,
              label: 'Yönetici Şifresi',
              hint: 'Kendi şifreniz',
              icon: Icons.admin_panel_settings,
              obscureText: _obscureAdminPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureAdminPassword ? Icons.visibility_off : Icons
                      .visibility,
                  color: isDark ? AppColors.darkTextSecondary : AppColors
                      .textSecondary,
                ),
                onPressed: () {
                  setState(() =>
                  _obscureAdminPassword = !_obscureAdminPassword);
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Yönetici şifresi gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _isLoading ? null : _handleAddUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.darkPrimary : AppColors
                    .primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
                  : const Text(
                'Kullanıcıyı Oluştur',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required bool isDark,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors
              .textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark
                ? AppColors.darkTextSecondary.withOpacity(0.5)
                : AppColors.textHint),
            prefixIcon: Icon(icon,
                color: isDark ? AppColors.darkPrimary : AppColors.primary),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDark ? AppColors.darkBackground : AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rol Seçimi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border),
            borderRadius: BorderRadius.circular(12),
            color: isDark ? AppColors.darkBackground : AppColors.background,
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedRole,
            isExpanded: true,
            dropdownColor: isDark ? AppColors.darkCardBackground : Colors.white,
            style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors
                    .textPrimary),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              prefixIcon: Icon(Icons.admin_panel_settings,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary),
            ),
            items: const [
              DropdownMenuItem(
                value: 'admin',
                child: Text(
                    'Yönetici', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
              DropdownMenuItem(
                value: 'captain',
                child: Text(
                    'Kaptan', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
              DropdownMenuItem(
                value: 'user',
                child: Text(
                    'Kullanıcı', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedRole = value ?? 'user';
                _selectedCaptainId = null;
              });
            },
          ),
        ),
      ],
    );
   }
}