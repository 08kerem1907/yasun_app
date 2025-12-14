import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../constants/colors.dart';
import 'admin_task_management_screen.dart';
import 'captain_task_management_screen.dart';
import 'user_task_management_screen.dart';

class TaskManagementScreen extends StatefulWidget {
  final int initialTabIndex;

  const TaskManagementScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen> {
  final UserService _userService = UserService();
  UserModel? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Oturum bulunamadı';
            _isLoading = false;
          });
        }
        return;
      }

      final user = await _userService.getUser(firebaseUser.uid);

      if (mounted) {
        setState(() {
          _currentUser = user;
          _errorMessage = user == null ? 'Kullanıcı bilgisi alınamadı' : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Kullanıcı bilgisi alınırken hata: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Bir hata oluştu';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_currentUser == null) {
      return _buildErrorScreen();
    }

    return _buildRoleBasedScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              SizedBox(height: 16),
              Text(
                'Yükleniyor...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Kullanıcı bilgisi alınamadı',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lütfen tekrar giriş yapın',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context)
                      .pushReplacementNamed('/login'),
                  icon: const Icon(Icons.login),
                  label: const Text('Giriş Sayfasına Dön'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBasedScreen() {
    final user = _currentUser!;

    if (user.isAdmin) {
      return AdminTaskManagementScreen(
        initialTabIndex: widget.initialTabIndex,
      );
    } else if (user.isCaptain) {
      return CaptainTaskManagementScreen(
        initialTabIndex: widget.initialTabIndex,
      );
    } else {
      return UserTaskManagementScreen(
        initialTab: widget.initialTabIndex,
      );
    }
  }
}