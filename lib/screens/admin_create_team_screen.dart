import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
            content: Text('Takım başarıyla oluşturuldu ve kullanıcı rolleri güncellendi!'),
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildForm(),
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
            child: Text(
              'Yeni Takım Oluştur',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            const Row(
              children: [
                Icon(
                  Icons.group_add,
                  color: AppColors.primary,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Takım Bilgileri',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Yeni takım oluşturmak için takım adını, kaptanı ve üyeleri seçin.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Takım Adı
            _buildTextField(
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
            _buildCaptainSelector(),
            const SizedBox(height: 20),

            // Üye Seçimi
            _buildMemberSelector(),
            const SizedBox(height: 32),

            // Oluştur butonu
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: AppColors.primaryGradient,
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptainSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Takım Kaptanı Seçin',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
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
              return Text('Hata: ${snapshot.error}');
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('Kaptan olabilecek kullanıcı bulunamadı.');
            }

            final users = snapshot.data!
                .where((user) => user.role != 'admin') // Adminler kaptan olmasın
                .toList();

            return DropdownButtonFormField<UserModel>(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.star, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              hint: const Text('Kaptan seçin'),
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
                  _selectedMembers.removeWhere((member) => member.uid == newValue?.uid);
                });
              },
              validator: (value) => value == null ? 'Kaptan seçimi zorunludur.' : null,
            );
          },
        ),
      ],
    );
  }

  Widget _buildMemberSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Takım Üyelerini Seçin (Kaptan hariç)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
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
              return Text('Hata: ${snapshot.error}');
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('Üye olabilecek kullanıcı bulunamadı.');
            }

            final allUsers = snapshot.data!;
            // Kaptan ve admin olmayan kullanıcıları filtrele
            final availableMembers = allUsers
                .where((user) =>
                    user.uid != _selectedCaptain?.uid &&
                    user.role != 'admin')
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8.0,
                  children: availableMembers.map((user) {
                    final isSelected = _selectedMembers.any((member) => member.uid == user.uid);
                    return FilterChip(
                      label: Text(user.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedMembers.add(user);
                          } else {
                            _selectedMembers.removeWhere((member) => member.uid == user.uid);
                          }
                        });
                      },
                      backgroundColor: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.background,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seçilen Üye Sayısı: ${_selectedMembers.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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
