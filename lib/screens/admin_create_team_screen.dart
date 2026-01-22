import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/team_service.dart';

class AdminCreateTeamScreen extends StatefulWidget {
  const AdminCreateTeamScreen({super.key});

  @override
  State<AdminCreateTeamScreen> createState() => _AdminCreateTeamScreenState();
}

class _AdminCreateTeamScreenState extends State<AdminCreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  UserModel? _selectedCaptain;
  List<UserModel> _selectedMembers = [];
  bool _isLoading = false;

  final UserService _userService = UserService();
  final TeamService _teamService = TeamService();

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateTeam() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCaptain == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir takım kaptanı seçin.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Kaptan ve üyeler listesi
      final captain = _selectedCaptain!;
      final members = _selectedMembers;

      // Takım oluşturma servisini çağır
      await _teamService.createTeam(
        teamName: _teamNameController.text.trim(),
        captain: captain,
        members: members,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Takım başarıyla oluşturuldu ve kullanıcı rolleri güncellendi!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Takım oluşturulurken hata: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            icon: Icon(Icons.arrow_back, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Yeni Takım Oluştur',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
            // Başlık
            Row(
              children: [
                Icon(
                  Icons.group_add,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Takım Bilgileri',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Yeni takım oluşturmak için takım adını, kaptanı ve üyeleri seçin.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Takım Adı
            _buildTextField(
              isDark: isDark,
              controller: _teamNameController,
              label: 'Takım Adı',
              hint: 'Örn: A Takımı',
              icon: Icons.group,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Takım adı gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Kaptan Seçimi
            _buildCaptainSelector(isDark),
            const SizedBox(height: 20),

            // Üye Seçimi
            _buildMemberSelector(isDark),
            const SizedBox(height: 32),

            // Oluştur butonu
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: isDark
                    ? LinearGradient(
                  colors: [
                    AppColors.darkPrimary,
                    AppColors.darkPrimary.withOpacity(0.8),
                  ],
                )
                    : AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? AppColors.darkPrimary : AppColors.primary).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleCreateTeam,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                    : const Text(
                  'Takımı Oluştur',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
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
          validator: validator,
          style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary.withOpacity(0.5) : AppColors.textHint),
            prefixIcon: Icon(icon, color: isDark ? AppColors.darkPrimary : AppColors.textSecondary),
            filled: true,
            fillColor: isDark ? AppColors.darkBackground : AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? AppColors.darkPrimary : AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptainSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Takım Kaptanı Seçin',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<UserModel>>(
          stream: _userService.getAllUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Hata: ${snapshot.error}', style: const TextStyle(color: AppColors.error));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text('Kaptan olabilecek kullanıcı bulunamadı.', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary));
            }

            final users = snapshot.data!
                .where(
                    (user) => user.role != 'admin') // Adminler kaptan olmasın
                .toList();

            return DropdownButtonFormField<UserModel>(
              dropdownColor: isDark ? AppColors.darkCardBackground : Colors.white,
              style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.star, color: isDark ? AppColors.darkPrimary : AppColors.textSecondary),
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? AppColors.darkPrimary : AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              hint: Text('Kaptan seçin', style: TextStyle(color: isDark ? AppColors.darkTextSecondary.withOpacity(0.5) : AppColors.textHint)),
              value: _selectedCaptain,
              items: users.map((user) {
                return DropdownMenuItem<UserModel>(
                  value: user,
                  child: Text('${user.displayName} (${user.email})'),
                );
              }).toList(),
              onChanged: (UserModel? newValue) {
                setState(() {
                  _selectedCaptain = newValue;
                  // Kaptan seçildiğinde, üyeler listesinden kaptanı çıkar
                  _selectedMembers
                      .removeWhere((member) => member.uid == newValue?.uid);
                });
              },
              validator: (value) =>
              value == null ? 'Kaptan seçimi zorunludur.' : null,
            );
          },
        ),
      ],
    );
  }

  Widget _buildMemberSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Takım Üyelerini Seçin (Kaptan hariç)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<UserModel>>(
          stream: _userService.getAllUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Hata: ${snapshot.error}', style: const TextStyle(color: AppColors.error));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text('Üye olabilecek kullanıcı bulunamadı.', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary));
            }

            final allUsers = snapshot.data!;
            // Kaptan ve admin olmayan kullanıcıları filtrele
            final availableMembers = allUsers
                .where((user) =>
            user.uid != _selectedCaptain?.uid && user.role != 'admin')
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8.0,
                  children: availableMembers.map((user) {
                    final isSelected = _selectedMembers
                        .any((member) => member.uid == user.uid);
                    return FilterChip(
                      label: Text(user.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedMembers.add(user);
                          } else {
                            _selectedMembers.removeWhere(
                                    (member) => member.uid == user.uid);
                          }
                        });
                      },
                      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
                      selectedColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                              : (isDark ? AppColors.darkBorder : AppColors.border),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seçilen Üye Sayısı: ${_selectedMembers.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
