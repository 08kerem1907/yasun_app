import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/team_model.dart';
import '../services/user_service.dart';
import '../services/team_service.dart';
import 'admin_add_user_screen_fixed.dart';
import 'admin_create_team_screen.dart';

// Dark Mode'da da sabit kalması gereken özel durum renkleri.
const Color _successColor = Color(0xFF4CAF50); // AppColors.success
const Color _warningColor = Color(0xFFFFC107); // AppColors.warning
const Color _errorColor = Color(0xFFF44336); // AppColors.error

// InheritedWidget ile tab değiştirme fonksiyonunu paylaş
class UsersListNavigator extends InheritedWidget {
  final Function(int) changeTab;

  const UsersListNavigator({
    super.key,
    required this.changeTab,
    required super.child,
  });

  static UsersListNavigator? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<UsersListNavigator>();
  }

  @override
  bool updateShouldNotify(UsersListNavigator oldWidget) {
    return false;
  }
}

class UsersListScreen extends StatefulWidget {
  final int initialTab; // ✅ YENİ PARAMETRE

  const UsersListScreen({
    super.key,
    this.initialTab = 0, // ✅ YENİ PARAMETRE
  });

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final TeamService _teamService = TeamService();

  late TabController _tabController;
  String _searchQuery = '';

  // Genişletilmiş takımları saklamak için
  final Set<String> _expandedTeams = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTab, // ✅ YENİ: Başlangıç tab'ı ayarla
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return UsersListNavigator(
      changeTab: (int index) {
        if (_tabController.index != index) {
          _tabController.animateTo(index);
        }
      },
      child: Scaffold(
        body: Container(
          color: colorScheme.background,
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(colorScheme),
                _buildTabBar(colorScheme),
                _buildSearchBar(colorScheme),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllUsersList(colorScheme),
                      _buildRoleBasedList('admin', colorScheme),
                      _buildRoleBasedList('captain', colorScheme),
                      _buildRoleBasedList('user', colorScheme),
                      _buildTeamsList(colorScheme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık satırı
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                Icon(Icons.people, color: colorScheme.onPrimary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Kullanıcı Listesi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Butonlar satırı
          Row(
            children: [
              // Kullanıcı Ekle Butonu
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminAddUserScreen(),
                        ),
                      );
                      if (result == true && mounted) {
                        setState(() {});
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    icon: Icon(Icons.person_add,
                        size: 20, color: colorScheme.onPrimary),
                    label: Text(
                      'Kullanıcı Ekle',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Takım Oluştur Butonu
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: _successColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _successColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminCreateTeamScreen(),
                        ),
                      );
                      if (result == true && mounted) {
                        setState(() {});
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    icon: Icon(Icons.group_add,
                        size: 20, color: colorScheme.onPrimary),
                    label: Text(
                      'Takım Oluştur',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: colorScheme.primary,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        tabs: const [
          Tab(text: 'Tümü'),
          Tab(text: 'Yöneticiler'),
          Tab(text: 'Kaptanlar'),
          Tab(text: 'Kullanıcılar'),
          Tab(text: 'Takımlar'),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: colorScheme.surface,
      child: TextField(
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
        decoration: InputDecoration(
          hintText: 'İsim veya email ile ara...',
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: TextStyle(color: colorScheme.onSurface),
      ),
    );
  }

  Widget _buildAllUsersList(ColorScheme colorScheme) {
    return StreamBuilder<List<UserModel>>(
      stream: _userService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: colorScheme.primary));
        }

        if (snapshot.hasError) {
          return Center(
              child: Text('Hata: ${snapshot.error}',
                  style: TextStyle(color: colorScheme.error)));
        }

        var users = snapshot.data ?? [];

        if (_searchQuery.isNotEmpty) {
          users = users.where((user) {
            return user.displayName.toLowerCase().contains(_searchQuery) ||
                user.email.toLowerCase().contains(_searchQuery);
          }).toList();
        }

        if (users.isEmpty) {
          return _buildEmptyState('Kullanıcı bulunamadı', colorScheme);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            return _buildUserCard(users[index], colorScheme);
          },
        );
      },
    );
  }

  Widget _buildRoleBasedList(String role, ColorScheme colorScheme) {
    return StreamBuilder<List<UserModel>>(
      stream: _userService.getUsersByRole(role),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: colorScheme.primary));
        }

        if (snapshot.hasError) {
          return Center(
              child: Text('Hata: ${snapshot.error}',
                  style: TextStyle(color: colorScheme.error)));
        }

        var users = snapshot.data ?? [];

        if (_searchQuery.isNotEmpty) {
          users = users.where((user) {
            return user.displayName.toLowerCase().contains(_searchQuery) ||
                user.email.toLowerCase().contains(_searchQuery);
          }).toList();
        }

        if (users.isEmpty) {
          String emptyMessage = 'Henüz ';
          if (role == 'admin')
            emptyMessage += 'yönetici';
          else if (role == 'captain')
            emptyMessage += 'kaptan';
          else
            emptyMessage += 'kullanıcı';
          emptyMessage += ' bulunmamaktadır.';

          return _buildEmptyState(emptyMessage, colorScheme);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            return _buildUserCard(users[index], colorScheme);
          },
        );
      },
    );
  }

  Widget _buildTeamsList(ColorScheme colorScheme) {
    return StreamBuilder<List<TeamModel>>(
      stream: _teamService.getAllTeams(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: colorScheme.primary));
        }

        if (snapshot.hasError) {
          return Center(
              child: Text('Hata: ${snapshot.error}',
                  style: TextStyle(color: colorScheme.error)));
        }

        var teams = snapshot.data ?? [];

        if (_searchQuery.isNotEmpty) {
          teams = teams.where((team) {
            return team.name.toLowerCase().contains(_searchQuery);
          }).toList();
        }

        if (teams.isEmpty) {
          return _buildEmptyState('Henüz takım oluşturulmamış.', colorScheme);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: teams.length,
          itemBuilder: (context, index) {
            return _buildTeamCard(teams[index], colorScheme);
          },
        );
      },
    );
  }

  Widget _buildTeamCard(TeamModel team, ColorScheme colorScheme) {
    final isExpanded = _expandedTeams.contains(team.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedTeams.remove(team.id);
                } else {
                  _expandedTeams.add(team.id);
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: isExpanded ? 0.25 : 0,
                    child: Icon(
                      Icons.chevron_right,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.groups,
                      color: colorScheme.onPrimary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${team.memberIds.length} üye',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isExpanded ? 'Kapat' : 'Aç',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: colorScheme.outline),
            _buildTeamMembers(team, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamMembers(TeamModel team, ColorScheme colorScheme) {
    return FutureBuilder<UserModel?>(
      future: _userService.getUser(team.captainId),
      builder: (context, captainSnapshot) {
        if (captainSnapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
                child: CircularProgressIndicator(color: colorScheme.primary)),
          );
        }

        final captain = captainSnapshot.data;

        return StreamBuilder<List<UserModel>>(
          stream: _userService.getTeamMembers(team.captainId),
          builder: (context, membersSnapshot) {
            if (membersSnapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                    child:
                    CircularProgressIndicator(color: colorScheme.primary)),
              );
            }

            final members = membersSnapshot.data ?? [];

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (captain != null) ...[
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _warningColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTeamMemberItem(
                            captain,
                            colorScheme,
                            isLeader: true,
                            icon: Icons.star,
                            iconColor: _warningColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (members.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        'Takım Üyeleri',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...members.map((member) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _successColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTeamMemberItem(
                                member,
                                colorScheme,
                                isLeader: false,
                                icon: Icons.person,
                                iconColor: _successColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                  if (members.isEmpty && captain != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(left: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Bu takımda henüz üye bulunmamaktadır.',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTeamMemberItem(
      UserModel user,
      ColorScheme colorScheme, {
        required bool isLeader,
        required IconData icon,
        required Color iconColor,
      }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
          isLeader ? _warningColor.withOpacity(0.3) : colorScheme.outline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (isLeader)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'KAPTAN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _warningColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${user.totalScore} puan',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user, ColorScheme colorScheme) {
    Color roleColor;
    IconData roleIcon;
    String roleText;

    switch (user.role) {
      case 'admin':
        roleColor = colorScheme.primary;
        roleIcon = Icons.shield;
        roleText = "Yönetici";
        break;

      case 'captain':
        roleColor = _warningColor;
        roleIcon = Icons.star;
        roleText = "Kaptan";
        break;

      default:
        roleColor = _successColor;
        roleIcon = Icons.person;
        roleText = "Kullanıcı";
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(roleIcon, color: roleColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  roleText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: roleColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              IconButton(
                icon: const Icon(Icons.delete_forever, color: _errorColor),
                onPressed: () => _showDeleteConfirmation(user, colorScheme),
                tooltip: 'Kullanıcıyı Sil',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(UserModel user, ColorScheme colorScheme) async {
    final currentUser = await _userService.getCurrentUser();

    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Hata: Yönetici bilgisi alınamadı.'),
            backgroundColor: _errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text('Kullanıcıyı Sil',
            style: TextStyle(color: colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${user.displayName} adlı kullanıcıyı silmek istediğinize emin misiniz?',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _errorColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: _errorColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bu işlem geri alınamaz ve kullanıcının tüm verileri silinir!',
                      style: TextStyle(
                        fontSize: 12,
                        color: _errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal',
                style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _userService.deleteUser(
                  user.uid,
                  deletedByAdminUid: currentUser.uid,
                  deletedByAdminName: currentUser.displayName,
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${user.displayName} başarıyla silindi'),
                      backgroundColor: _successColor,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: _errorColor,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorColor,
            ),
            child: Text('Sil', style: TextStyle(color: colorScheme.onError)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
