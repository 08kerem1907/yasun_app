import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart'; // Eğer AppColors içerisindeki özel renkler (success, warning, error vb.) farklı bir yerde kullanılmıyorsa bu import kaldırılabilir. Tema renkleri için gerek kalmadı.
import '../models/user_model.dart';
import '../services/auth_service_fixed.dart';
import '../services/user_service.dart';

// Mevcut AppColors dosyasından dark mode'da da sabit kalmasını istediğimiz özel durum renklerini alıyoruz.
// Bunlar tema renk şemasına dahil edilmediği için elle tanımlayalım veya import edelim.
// NOT: Gerçek bir Material 3 projesinde bu renkler de ColorScheme'e dahil edilmelidir.
// Ancak mevcut yapıyı korumak adına, aşağıdaki özel renkleri doğrudan kullanıyoruz.
const Color _primaryColor = Color(0xFF4A148C); // AppColors.primary (Örnek sabit bir değer)
const Color _primaryLightColor = Color(0xFF6A1B9A);
const Color _successColor = Color(0xFF4CAF50); // AppColors.success
const Color _warningColor = Color(0xFFFFC107); // AppColors.warning
const Color _errorColor = Color(0xFFF44336); // AppColors.error
const Color _infoColor = Color(0xFF2196F3); // AppColors.info

class MyTeamScreen extends StatefulWidget {
  const MyTeamScreen({super.key});

  @override
  State<MyTeamScreen> createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends State<MyTeamScreen> {
  final UserService _userService = UserService();
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    if (currentUser == null) {
      return Scaffold(
        body: Center(child: Text('Kullanıcı bulunamadı', style: TextStyle(color: colorScheme.onSurface))),
      );
    }

    return StreamBuilder<UserModel?>(
      stream: authService.getUserDataStream(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            body: Center(child: Text('Kullanıcı verileri yüklenemedi', style: TextStyle(color: colorScheme.onSurface))),
          );
        }

        final userData = snapshot.data!;

        // Sadece captain'lar bu ekranı görebilir
        if (!userData.isCaptain) {
          return _buildNoPermission(colorScheme);
        }

        return Scaffold(
          body: Container(
            // Arka plan gradient yerine tema background rengi kullanılabilir
            color: colorScheme.background,
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(context, userData, colorScheme),
                  _buildTeamStats(userData, colorScheme),
                  _buildFilterChips(colorScheme),
                  Expanded(
                    child: _buildTeamMembersList(userData, colorScheme),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddMemberDialog(userData, colorScheme),
            icon: const Icon(Icons.person_add),
            label: const Text('Üye Ekle'),
            backgroundColor: colorScheme.primary, // Tema primary renk
            foregroundColor: colorScheme.onPrimary, // Tema onPrimary renk
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, UserModel userData, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface, // Tema Surface rengi
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              // Gradient yerine primary rengin bir türevi veya kendisi kullanılabilir
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.groups_rounded,
              color: colorScheme.onPrimary, // Tema onPrimary rengi
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ekibim',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface, // Tema onSurface rengi
                  ),
                ),
                Text(
                  'Kaptan: ${userData.displayName}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant, // Tema onSurfaceVariant rengi
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStats(UserModel userData, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface, // Tema Surface rengi
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: FutureBuilder<Map<String, int>>(
        future: Future.wait([
          _userService.getTeamMemberCount(userData.uid),
          _userService.getCompletedTasksThisMonth(userData.uid),
          _userService.getTotalScore(userData.uid),
        ]).then((responses) {
          return {
            'team_members': responses[0],
            'completed_tasks': responses[1],
            'total_score': responses[2],
          };
        }),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: CircularProgressIndicator(color: colorScheme.primary),
              ),
            );
          }

          final stats = snapshot.data!;

          return Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: 'Ekip Üyeleri',
                  value: (stats['team_members'] ?? 0).toString(),
                  icon: Icons.people,
                  color: colorScheme.primary, // Tema primary
                  textColor: colorScheme.onSurface,
                  labelColor: colorScheme.onSurfaceVariant,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: colorScheme.outline, // Tema outline rengi
              ),
              Expanded(
                child: _buildStatItem(
                  label: 'Toplam Puan',
                  value: (stats['total_score'] ?? 0).toString(),
                  icon: Icons.emoji_events_rounded,
                  color: _warningColor, // Sabit renk
                  textColor: colorScheme.onSurface,
                  labelColor: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color textColor,
    required Color labelColor,
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
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor, // Tema onSurface
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: labelColor, // Tema onSurfaceVariant
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildFilterChips(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Tümü', 'all', Icons.people, colorScheme),
            const SizedBox(width: 8),
            _buildFilterChip('Aktif Üyeler', 'active', Icons.check_circle, colorScheme),
            const SizedBox(width: 8),
            _buildFilterChip('En Yüksek Puan', 'top_score', Icons.star, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon, ColorScheme colorScheme) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? colorScheme.onPrimary : colorScheme.primary, // Seçili: onPrimary, Değil: Primary
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor: colorScheme.surface, // Tema Surface
      selectedColor: colorScheme.primary, // Tema Primary
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface, // Seçili: onPrimary, Değil: onSurface
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outline, // Seçili: Primary, Değil: Outline
        ),
      ),
    );
  }

  Widget _buildTeamMembersList(UserModel userData, ColorScheme colorScheme) {
    return StreamBuilder<List<UserModel>>(
      stream: _userService.getTeamMembers(userData.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: colorScheme.primary));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Hata: ${snapshot.error}',
                  style: TextStyle(color: colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(userData, colorScheme);
        }

        var members = snapshot.data!;

        // Sıralama ve Filtreleme
        if (_selectedFilter == 'all') {
          // "Tümü" filtresi için alfabetik sıralama
          members.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
        } else if (_selectedFilter == 'active') {
          // "Aktif" filtresi için filtreleme ve alfabetik sıralama
          members = members.where((m) => m.lastLogin != null).toList();
          members.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
        } else if (_selectedFilter == 'top_score') {
          // "En Yüksek Puan" filtresi için puana göre azalan sıralama
          // UserModel'deki totalScore alanı kullanılıyor.
          members.sort((a, b) => b.totalScore.compareTo(a.totalScore));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: members.length,
          itemBuilder: (context, index) {
            return _buildMemberCard(members[index], userData, colorScheme);
          },
        );
      },
    );
  }
  Widget _buildMemberCard(UserModel member, UserModel captain, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface, // Tema Surface
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showMemberDetailsDialog(member, colorScheme),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.primary, // Tema Primary
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      member.displayName.isNotEmpty
                          ? member.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary, // Tema onPrimary
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Member Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface, // Tema onSurface
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant, // Tema onSurfaceVariant
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildMemberBadge(member),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: colorScheme.onSurfaceVariant, // Tema onSurfaceVariant
                          ),
                          const SizedBox(width: 4),
                          Text(
                            member.lastLogin != null
                                ? _formatDate(member.lastLogin!)
                                : 'Hiç giriş yapmadı',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant, // Tema onSurfaceVariant
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Stats & Actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FutureBuilder<int>(
                      future: _userService.getTotalScore(member.uid),
                      builder: (context, snapshot) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _warningColor.withOpacity(0.1), // Sabit renk
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.score,
                                size: 14,
                                color: _warningColor, // Sabit renk
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (snapshot.data ?? 0).toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _warningColor, // Sabit renk
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: colorScheme.onSurfaceVariant, // Tema onSurfaceVariant
                        size: 20,
                      ),
                      onPressed: () => _showMemberOptionsMenu(member, captain, colorScheme),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberBadge(UserModel member) {
    Color color = _successColor; // Sabit renk
    IconData icon = Icons.person;
    String label = 'Üye';

    if (member.role == 'captain') {
      color = _warningColor; // Sabit renk
      icon = Icons.star;
      label = 'Kaptan';
    } else if (member.role == 'admin') {
      color = _errorColor; // Sabit renk
      icon = Icons.admin_panel_settings;
      label = 'Yönetici';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Az önce';
        }
        return '${difference.inMinutes} dk önce';
      }
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return DateFormat('dd.MM.yyyy').format(date);
    }
  }

  void _showMemberDetailsDialog(UserModel member, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface, // Tema Surface
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primary, // Tema Primary
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  member.displayName.isNotEmpty
                      ? member.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary, // Tema onPrimary
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Üye Detayları',
                style: TextStyle(color: colorScheme.onSurface), // Tema onSurface
              ),
            ),
          ],
        ),
        content: FutureBuilder<Map<String, int>>(
          future: Future.wait([
            _userService.getActiveTaskCount(member.uid),
            _userService.getCompletedTaskCount(member.uid),
            _userService.getTotalScore(member.uid),
          ]).then((responses) {
            return {
              'active_tasks': responses[0],
              'completed_tasks': responses[1],
              'total_score': responses[2],
            };
          }),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
              );
            }

            final stats = snapshot.data!;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Ad Soyad', member.displayName, colorScheme),
                const SizedBox(height: 12),
                _buildDetailRow('Email', member.email, colorScheme),
                const SizedBox(height: 12),
                _buildDetailRow('Rol', member.roleDisplayName, colorScheme),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Kayıt Tarihi',
                  DateFormat('dd.MM.yyyy').format(member.createdAt),
                  colorScheme,
                ),
                if (member.lastLogin != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Son Giriş',
                    DateFormat('dd.MM.yyyy HH:mm').format(member.lastLogin!),
                    colorScheme,
                  ),
                ],
                Divider(height: 32, color: colorScheme.outline), // Tema outline
                Text(
                  'İstatistikler',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface, // Tema onSurface
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Aktif Görevler',
                  (stats['active_tasks'] ?? 0).toString(),
                  colorScheme,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Tamamlanan Görevler',
                  (stats['completed_tasks'] ?? 0).toString(),
                  colorScheme,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Toplam Puan',
                  (stats['total_score'] ?? 0).toString(),
                  colorScheme,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat', style: TextStyle(color: colorScheme.primary)), // Tema Primary
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant, // Tema onSurfaceVariant
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface, // Tema onSurface
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showMemberOptionsMenu(UserModel member, UserModel captain, ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface, // Tema Surface
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline, // Tema Outline
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.assignment, color: colorScheme.primary), // Tema Primary
              title: Text('Görev Ata', style: TextStyle(color: colorScheme.onSurface)), // Tema onSurface
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Görev atama özelliği yakında eklenecek'),
                    backgroundColor: _infoColor, // Sabit renk
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.message, color: colorScheme.primary), // Tema Primary
              title: Text('Mesaj Gönder', style: TextStyle(color: colorScheme.onSurface)), // Tema onSurface
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Mesajlaşma özelliği yakında eklenecek'),
                    backgroundColor: _infoColor, // Sabit renk
                  ),
                );
              },
            ),
            Divider(color: colorScheme.outline), // Tema Outline
            ListTile(
              leading: const Icon(Icons.person_remove, color: _errorColor), // Sabit renk
              title: const Text('Takımdan Çıkar', style: TextStyle(color: _errorColor)), // Sabit renk
              onTap: () {
                Navigator.pop(context);
                _showRemoveMemberDialog(member, colorScheme);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveMemberDialog(UserModel member, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface, // Tema Surface
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('Üyeyi Çıkar', style: TextStyle(color: colorScheme.onSurface)), // Tema onSurface
        content: Text(
          '${member.displayName} üyesini takımdan çıkarmak istediğinize emin misiniz?',
          style: TextStyle(color: colorScheme.onSurfaceVariant), // Tema onSurfaceVariant
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: colorScheme.onSurfaceVariant)), // Tema onSurfaceVariant
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _userService.updateUserCaptain(member.uid, null);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${member.displayName} takımdan çıkarıldı'),
                      backgroundColor: _successColor, // Sabit renk
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: _errorColor, // Sabit renk
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorColor, // Sabit renk
              foregroundColor: Colors.white,
            ),
            child: const Text('Çıkar'),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(UserModel captain, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: colorScheme.surface, // Tema Surface
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primary, // Tema Primary
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: colorScheme.onPrimary), // Tema onPrimary
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ekibe Üye Ekle',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary, // Tema onPrimary
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colorScheme.onPrimary), // Tema onPrimary
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: _buildAvailableUsersList(captain, colorScheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableUsersList(UserModel captain, ColorScheme colorScheme) {
    return StreamBuilder<List<UserModel>>(
      stream: _userService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: colorScheme.primary));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Hata: ${snapshot.error}', style: TextStyle(color: colorScheme.error)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text('Kullanıcı bulunamadı', style: TextStyle(color: colorScheme.onSurface)),
          );
        }

        // Takıma eklenmemiş ve captain/admin olmayan kullanıcıları filtrele
        final availableUsers = snapshot.data!.where((user) {
          return user.captainId == null &&
              user.role == 'user' &&
              user.uid != captain.uid;
        }).toList();

        if (availableUsers.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _infoColor.withOpacity(0.1), // Sabit renk
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      size: 48,
                      color: _infoColor, // Sabit renk
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Eklenebilecek Üye Yok',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface, // Tema onSurface
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tüm kullanıcılar bir takıma atanmış\nveya yetkili pozisyonlarda',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant, // Tema onSurfaceVariant
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: availableUsers.length,
          itemBuilder: (context, index) {
            return _buildAvailableUserCard(availableUsers[index], captain, colorScheme);
          },
        );
      },
    );
  }

  Widget _buildAvailableUserCard(UserModel user, UserModel captain, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface, // Tema Surface
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline), // Tema Outline
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.primary, // Tema Primary
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              user.displayName.isNotEmpty
                  ? user.displayName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary, // Tema onPrimary
              ),
            ),
          ),
        ),
        title: Text(
          user.displayName,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface, // Tema onSurface
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user.email,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant, // Tema onSurfaceVariant
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<int>(
              future: _userService.getTotalScore(user.uid),
              builder: (context, snapshot) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _successColor.withOpacity(0.1), // Sabit renk
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.score,
                        size: 12,
                        color: _successColor, // Sabit renk
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Puan: ${snapshot.data ?? 0}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _successColor, // Sabit renk
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _addMemberToTeam(user, captain, colorScheme),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary, // Tema Primary
            foregroundColor: colorScheme.onPrimary, // Tema onPrimary
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Ekle',
            style: TextStyle(fontSize: 13),
          ),
        ),
      ),
    );
  }

  Future<void> _addMemberToTeam(UserModel user, UserModel captain, ColorScheme colorScheme) async {
    try {
      // Kullanıcının teamId'sini captain'ın uid'si ile güncelle
      await _userService.updateUserCaptain(user.uid, captain.uid);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.displayName} ekibe eklendi!'),
            backgroundColor: _successColor, // Sabit renk
            action: SnackBarAction(
              label: 'Geri Al',
              textColor: colorScheme.onPrimary,
              onPressed: () async {
                await _userService.updateUserCaptain(user.uid, null);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: _errorColor, // Sabit renk
          ),
        );
      }
    }
  }

  Widget _buildEmptyState(UserModel userData, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1), // Tema Primary
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 64,
              color: colorScheme.primary, // Tema Primary
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Henüz Ekip Üyesi Yok',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface, // Tema onSurface
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ekibinize üye ekleyerek başlayın',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant, // Tema onSurfaceVariant
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddMemberDialog(userData, colorScheme),
            icon: Icon(Icons.person_add, color: colorScheme.onPrimary), // Tema onPrimary
            label: Text('Üye Ekle', style: TextStyle(color: colorScheme.onPrimary)), // Tema onPrimary
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary, // Tema Primary
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPermission(ColorScheme colorScheme) {
    return Scaffold(
      body: Container(
        color: colorScheme.background, // Tema Background
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.error.withOpacity(0.1), // Tema Error
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: colorScheme.error, // Tema Error
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Yetkiniz Yok',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface, // Tema onSurface
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bu sayfayı görüntülemek için\nkaptan yetkisine sahip olmalısınız',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant, // Tema onSurfaceVariant
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}