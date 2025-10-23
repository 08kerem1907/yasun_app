import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class AdminManageTeamsScreen extends StatefulWidget {
  const AdminManageTeamsScreen({super.key});

  @override
  State<AdminManageTeamsScreen> createState() => _AdminManageTeamsScreenState();
}

class _AdminManageTeamsScreenState extends State<AdminManageTeamsScreen> {
  final UserService _userService = UserService();
  String _searchQuery = '';

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
              _buildAppBar(),
              _buildSearchBar(),
              Expanded(
                child: _buildTeamsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
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
              'Takımları Yönet',
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

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
        decoration: InputDecoration(
          hintText: 'Takım ara...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamsList() {
    return StreamBuilder<List<UserModel>>(
      stream: _userService.getUsersByRole('captain'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        var captains = snapshot.data ?? [];

        // Arama filtresi uygula
        if (_searchQuery.isNotEmpty) {
          captains = captains
              .where((captain) =>
              captain.displayName.toLowerCase().contains(_searchQuery))
              .toList();
        }

        if (captains.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group_off,
                  size: 64,
                  color: Colors.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Takım bulunamadı',
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: captains.length,
          itemBuilder: (context, index) {
            return _buildTeamCard(captains[index]);
          },
        );
      },
    );
  }

  Widget _buildTeamCard(UserModel captain) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ExpansionTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.groups,
            color: Colors.blue,
          ),
        ),
        title: Text(
          captain.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(captain.email),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildTeamMembersSection(captain),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMembersSection(UserModel captain) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Takım Üyeleri',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<UserModel>>(
          stream: _userService.getTeamMembers(captain.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasError) {
              return Text('Hata: ${snapshot.error}');
            }

            final members = snapshot.data ?? [];

            if (members.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Bu takımda henüz üye bulunmamaktadır',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              );
            }

            return Column(
              children: members.map((member) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildMemberItem(member, captain),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showAddMemberDialog(captain),
            icon: const Icon(Icons.person_add),
            label: const Text('Üye Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberItem(UserModel member, UserModel captain) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  member.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'remove') {
                _showRemoveMemberConfirmation(member, captain);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.person_remove, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Çıkar'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(UserModel captain) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Takıma Üye Ekle'),
        content: StreamBuilder<List<UserModel>>(
          stream: _userService.getAllUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasError) {
              return Text('Hata: ${snapshot.error}');
            }

            // Takıma atanmamış kullanıcıları filtrele
            final availableUsers = (snapshot.data ?? [])
                .where((user) =>
            user.isUser &&
                (user.teamId == null || user.teamId!.isEmpty))
                .toList();

            if (availableUsers.isEmpty) {
              return const Text(
                'Takıma atanmamış kullanıcı bulunmamaktadır',
              );
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: availableUsers.map((user) {
                  return ListTile(
                    title: Text(user.displayName),
                    subtitle: Text(user.email),
                    onTap: () async {
                      try {
                        await _userService.updateUserTeam(user.uid, captain.uid);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Üye başarıyla eklendi'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          setState(() {});
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
                    },
                  );
                }).toList(),
              ),
            );
          },
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

  void _showRemoveMemberConfirmation(UserModel member, UserModel captain) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Üyeyi Çıkar'),
        content: Text(
          '${member.displayName} adlı üyeyi takımdan çıkarmak istediğinize emin misiniz?',
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
                    const SnackBar(
                      content: Text('Üye başarıyla çıkarıldı'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  setState(() {});
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Çıkar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

