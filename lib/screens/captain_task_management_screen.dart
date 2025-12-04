import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/colors.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';
import '../services/team_service.dart';
import 'package:intl/intl.dart';

class CaptainTaskManagementScreen extends StatefulWidget {
  const CaptainTaskManagementScreen({super.key});

  @override
  State<CaptainTaskManagementScreen> createState() => _CaptainTaskManagementScreenState();
}

class _CaptainTaskManagementScreenState extends State<CaptainTaskManagementScreen> {
  final TaskService _taskService = TaskService();
  final TeamService _teamService = TeamService();
  CaptainRating? _selectedRating;
  final UserService _userService = UserService();
  UserModel? _currentUser;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    try {
      User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        UserModel? user = await _userService.getUser(firebaseUser.uid);
        if (mounted) {
          setState(() {
            _currentUser = user;
          });
        }
      }
    } catch (e) {
      print('Hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.background,
              colorScheme.secondaryContainer.withOpacity(0.1)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(colorScheme, textTheme),
              _buildSegmentedControl(colorScheme, textTheme),
              Expanded(
                child: _buildCurrentPage(colorScheme, textTheme),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTaskDialog,
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Görev Ata'),
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Görev Yönetimi',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Kaptan Paneli',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.star, size: 16, color: colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Kaptan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: colorScheme.surface,
      child: Row(
        children: [
          Expanded(child: _buildSegmentButton(0, 'Bana Atanan', Icons.assignment_ind, colorScheme, textTheme)),
          const SizedBox(width: 8),
          Expanded(child: _buildSegmentButton(1, 'Değerlendirme', Icons.rate_review, colorScheme, textTheme)),
          const SizedBox(width: 8),
          Expanded(child: _buildSegmentButton(2, 'Takım Görevleri', Icons.people, colorScheme, textTheme)),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(int index, String label, IconData icon, ColorScheme colorScheme, TextTheme textTheme) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPage(ColorScheme colorScheme, TextTheme textTheme) {
    switch (_selectedIndex) {
      case 0:
        return _buildMyTasksPage(colorScheme, textTheme);
      case 1:
        return _buildEvaluationTasksPage(colorScheme, textTheme);
      case 2:
        return _buildTeamTasksPage(colorScheme, textTheme);
      default:
        return _buildMyTasksPage(colorScheme, textTheme);
    }
  }

  Widget _buildMyTasksPage(ColorScheme colorScheme, TextTheme textTheme) {
    if (_currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<TaskModel>>(
      stream: _taskService.getTasksAssignedToUser(_currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Hata: ${snapshot.error}',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
            ),
          );
        }

        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inbox,
            title: 'Henüz görev yok',
            subtitle: 'Size atanan görevler burada görünecek',
            colorScheme: colorScheme,
            textTheme: textTheme,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            return _buildTaskCard(tasks[index], colorScheme, textTheme);
          },
        );
      },
    );
  }

  Widget _buildEvaluationTasksPage(ColorScheme colorScheme, TextTheme textTheme) {
    if (_currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<TaskModel>>(
      stream: _taskService.getTasksForCaptainEvaluation(_currentUser!.teamId ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Hata: ${snapshot.error}',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
            ),
          );
        }

        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            title: 'Değerlendirilecek görev yok',
            subtitle: 'Ekip üyelerinin tamamladığı görevler burada görünecek',
            colorScheme: colorScheme,
            textTheme: textTheme,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            return _buildEvaluationTaskCard(tasks[index], colorScheme, textTheme);
          },
        );
      },
    );
  }

  Widget _buildTeamTasksPage(ColorScheme colorScheme, TextTheme textTheme) {
    if (_currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<UserModel>>(
      stream: _userService.getTeamMembers(_currentUser!.uid),
      builder: (context, teamSnapshot) {
        if (teamSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (teamSnapshot.hasError) {
          return Center(
            child: Text(
              'Hata: ${teamSnapshot.error}',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
            ),
          );
        }

        final teamMembers = teamSnapshot.data ?? [];

        if (teamMembers.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_outline,
            title: 'Takım üyesi yok',
            subtitle: 'Takımınıza üye eklendiğinde görevleri burada görünecek',
            colorScheme: colorScheme,
            textTheme: textTheme,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: teamMembers.length,
          itemBuilder: (context, index) {
            return _buildTeamMemberCard(teamMembers[index], colorScheme, textTheme);
          },
        );
      },
    );
  }

  Widget _buildTaskCard(TaskModel task, ColorScheme colorScheme, TextTheme textTheme, {bool showEditButton = true}) {
    Color statusColor = _getStatusColor(task.status);
    String statusText = _getStatusText(task.status);
    bool canComplete = task.status == TaskStatus.assigned;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTaskDetails(task),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'Atayan: ${task.assignedByDisplayName}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.calendar_today, size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(task.dueDate),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (task.updatedAt != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 14, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Düzenlendi: ${_formatDateTime(task.updatedAt!)}${task.updatedBy != null ? ' - ${task.updatedBy}' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (showEditButton && task.assignedByUid == _currentUser?.uid && task.status == TaskStatus.assigned) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: () => _showEditTaskDialog(task),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Düzenle'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            side: BorderSide(color: colorScheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _deleteTask(task.id, task.title),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Icon(Icons.delete_outline, size: 20),
                      ),
                    ],
                  ),
                ],
                if (canComplete) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCompleteTaskDialog(task),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Tamamla'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEvaluationDialog(TaskModel task) {
    final evaluationController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    _selectedRating = task.captainRating;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: colorScheme.surface,
              title: Text(
                'Görevi Değerlendir',
                style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Derece Seçin:',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: CaptainRating.values.map((rating) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: _buildRatingButton(rating, setState),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: evaluationController,
                      maxLines: 3,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Değerlendirme Notu',
                        hintText: 'Görev hakkındaki değerlendirmenizi yazın...',
                        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('İptal', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_selectedRating == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lütfen bir derece seçin (İyi, Orta, Kötü)'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }
                    if (evaluationController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lütfen bir değerlendirme notu yazın'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    await _taskService.evaluateTaskByCaptain(
                      task.id,
                      evaluationController.text,
                      _selectedRating!,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Görev değerlendirildi ve yönetime iletildi!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Onayla'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRatingButton(CaptainRating rating, StateSetter setState) {
    final isSelected = _selectedRating == rating;
    Color color;
    String text;

    switch (rating) {
      case CaptainRating.good:
        color = AppColors.success;
        text = 'İyi';
        break;
      case CaptainRating.medium:
        color = AppColors.warning;
        text = 'Orta';
        break;
      case CaptainRating.bad:
        color = AppColors.error;
        text = 'Kötü';
        break;
    }

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedRating = rating;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : color.withOpacity(0.1),
        foregroundColor: isSelected ? Colors.white : color,
        elevation: isSelected ? 4 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color, width: isSelected ? 2 : 1),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEvaluationTaskCard(TaskModel task, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.rate_review, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        task.assignedToDisplayName,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.description,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (task.userCompletionNote != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.note, size: 16, color: colorScheme.onSurface),
                        const SizedBox(width: 4),
                        Text(
                          'Tamamlanma Notu:',
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.userCompletionNote!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectTask(task),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reddet'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _showEvaluationDialog(task),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Onayla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMemberCard(UserModel member, ColorScheme colorScheme, TextTheme textTheme) {
    bool isExpanded = false;

    return StatefulBuilder(
      builder: (context, setStateCard) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
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
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setStateCard(() {
                      isExpanded = !isExpanded;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.7)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.displayName,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                member.email,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.stars, size: 14, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Puan: ${member.totalScore}',
                                    style: textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildMemberTasks(member, colorScheme, textTheme),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMemberTasks(UserModel member, ColorScheme colorScheme, TextTheme textTheme) {
    return StreamBuilder<List<TaskModel>>(
      stream: _taskService.getTasksAssignedToUser(member.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Text(
            'Hata: ${snapshot.error}',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
          );
        }

        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Bu üyeye henüz görev atanmamış',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          children: tasks.map((task) {
            bool isCreatedByCaptain = task.assignedByUid == _currentUser?.uid;
            bool canEdit = isCreatedByCaptain && task.status == TaskStatus.assigned;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(task.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusText(task.status),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(task.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'Bitiş: ${_formatDate(task.dueDate)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (task.updatedAt != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 12, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Düzenlendi: ${_formatDateTime(task.updatedAt!)}${task.updatedBy != null ? ' - ${task.updatedBy}' : ''}',
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (task.adminScore != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.stars, size: 12, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          'Puan: ${task.adminScore}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (canEdit || task.status != TaskStatus.assigned) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (canEdit) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showEditTaskDialog(task),
                              icon: const Icon(Icons.edit, size: 14),
                              label: const Text('Düzenle', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.primary,
                                side: BorderSide(color: colorScheme.primary),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          OutlinedButton(
                            onPressed: () => _deleteTask(task.id, task.title),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: const Size(0, 0),
                            ),
                            child: const Icon(Icons.delete_outline, size: 16),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showTaskDetails(task),
                            icon: const Icon(Icons.info_outline, size: 14),
                            label: const Text('Detay', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.onSurface,
                              side: BorderSide(color: colorScheme.outline),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateTaskDialog() async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bilgisi alınamadı.')),
      );
      return;
    }

    if (_currentUser!.teamId == null || _currentUser!.teamId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Takım bilgisi bulunamadı. Lütfen yöneticinizle iletişime geçin.')),
      );
      return;
    }

    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    DateTime? selectedDueDate;
    UserModel? selectedUser;
    int selectedDifficulty = 1;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: colorScheme.surface,
              title: Text(
                'Takıma Görev Ata',
                style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Görev Başlığı',
                        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Görev Açıklaması',
                        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.primary),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        selectedDueDate == null
                            ? 'Son Teslim Tarihi Seç'
                            : 'Son Teslim: ${selectedDueDate!.day}.${selectedDueDate!.month}.${selectedDueDate!.year}',
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                      ),
                      trailing: Icon(Icons.calendar_today, color: colorScheme.onSurfaceVariant),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          locale: const Locale('tr', 'TR'),
                        );
                        if (picked != null && picked != selectedDueDate) {
                          setState(() {
                            selectedDueDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Zorluk Derecesi',
                        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                        helperText: 'Puan bu değerle çarpılacaktır',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.primary),
                        ),
                      ),
                      value: selectedDifficulty,
                      style: TextStyle(color: colorScheme.onSurface),
                      dropdownColor: colorScheme.surface,
                      onChanged: (int? newValue) {
                        setState(() {
                          selectedDifficulty = newValue ?? 1;
                        });
                      },
                      items: const [
                        DropdownMenuItem<int>(
                          value: 1,
                          child: Text('1 - Kolay'),
                        ),
                        DropdownMenuItem<int>(
                          value: 2,
                          child: Text('2 - Orta'),
                        ),
                        DropdownMenuItem<int>(
                          value: 3,
                          child: Text('3 - Zor'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<List<UserModel>>(
                      stream: _userService.getTeamMembers(_currentUser!.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text(
                            'Hata: ${snapshot.error}',
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Text(
                            'Görev atanacak takım üyesi bulunamadı.',
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                          );
                        }

                        List<UserModel> assignableUsers = snapshot.data!
                            .where((user) => user.isUser)
                            .toList();

                        if (assignableUsers.isEmpty) {
                          return Text(
                            'Takımınızda görev atanabilecek üye yok.',
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                          );
                        }

                        return DropdownButtonFormField<UserModel>(
                          decoration: InputDecoration(
                            labelText: 'Görev Atanacak Takım Üyesi',
                            labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colorScheme.primary),
                            ),
                          ),
                          value: selectedUser,
                          style: TextStyle(color: colorScheme.onSurface),
                          dropdownColor: colorScheme.surface,
                          onChanged: (UserModel? newValue) {
                            setState(() {
                              selectedUser = newValue;
                            });
                          },
                          items: assignableUsers.map<DropdownMenuItem<UserModel>>((UserModel user) {
                            return DropdownMenuItem<UserModel>(
                              value: user,
                              child: Text('${user.displayName} - Puan: ${user.totalScore}'),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('İptal', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty ||
                        descriptionController.text.isEmpty ||
                        selectedDueDate == null ||
                        selectedUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lütfen tüm alanları doldurun.')),
                      );
                      return;
                    }

                    final assignedUserTeamId = selectedUser!.teamId;
                    String? assignedUserTeamName;

                    if (assignedUserTeamId != null) {
                      final team = await _teamService.getTeam(assignedUserTeamId);
                      assignedUserTeamName = team?.name;
                    }

                    final newTask = TaskModel(
                      id: '',
                      title: titleController.text,
                      description: descriptionController.text,
                      assignedToUid: selectedUser!.uid,
                      assignedToDisplayName: selectedUser!.displayName,
                      assignedToTeamId: assignedUserTeamId,
                      assignedToTeamName: assignedUserTeamName,
                      assignedByUid: _currentUser!.uid,
                      assignedByDisplayName: _currentUser!.displayName,
                      dueDate: selectedDueDate!,
                      createdAt: DateTime.now(),
                      status: TaskStatus.assigned,
                      difficultyLevel: selectedDifficulty,
                    );

                    await _taskService.createTask(newTask);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Görev başarıyla atandı!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Görev Ata'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCompleteTaskDialog(TaskModel task) {
    final noteController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Görevi Tamamla',
          style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 3,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Tamamlanma Notu',
                hintText: 'Görev hakkında notlarınızı yazın...',
                labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (noteController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen bir not girin'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              await _taskService.completeTask(task.id, noteController.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Görev başarıyla tamamlandı!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tamamla'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditTaskDialog(TaskModel task) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final TextEditingController titleController = TextEditingController(text: task.title);
    final TextEditingController descriptionController = TextEditingController(text: task.description);
    DateTime selectedDueDate = task.dueDate;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: colorScheme.surface,
              title: Text(
                'Görevi Düzenle',
                style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Görev Başlığı',
                        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Görev Açıklaması',
                        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.primary),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Son Teslim: ${selectedDueDate.day}.${selectedDueDate.month}.${selectedDueDate.year}',
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                      ),
                      trailing: Icon(Icons.calendar_today, color: colorScheme.onSurfaceVariant),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDueDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null && picked != selectedDueDate) {
                          setState(() {
                            selectedDueDate = picked;
                          });
                        }
                      },
                    ),
                    if (task.updatedAt != null) ...[
                      const Divider(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.edit, size: 16, color: colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Son Düzenleme:',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatDateTime(task.updatedAt!)}',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (task.updatedBy != null)
                              Text(
                                'Düzenleyen: ${task.updatedBy}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('İptal', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lütfen tüm alanları doldurun.')),
                      );
                      return;
                    }

                    await _taskService.updateTaskWithInfo(
                      task.id,
                      titleController.text,
                      descriptionController.text,
                      selectedDueDate,
                      _currentUser!.displayName,
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Görev başarıyla güncellendi!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Güncelle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _rejectTask(TaskModel task) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Görevi Reddet',
          style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
        ),
        content: Text(
          'Bu görev reddedilecek ve kullanıcıya geri gönderilecek. Devam etmek istiyor musunuz?',
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _taskService.updateTask(
                task.copyWith(status: TaskStatus.assigned),
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Görev reddedildi ve kullanıcıya geri gönderildi'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(String taskId, String taskTitle) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            const SizedBox(width: 12),
            Text(
              'Görevi Sil',
              style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
            ),
          ],
        ),
        content: Text(
          'Bu görevi silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz ve görevle ilgili tüm veriler silinecektir.',
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Evet, Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _taskService.deleteTask(
          taskId,
          _currentUser!.displayName,
          taskTitle,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Görev başarıyla silindi'),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Hata: $e')),
                ],
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _showTaskDetails(TaskModel task) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          task.title,
          style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Açıklama: ${task.description}',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                'Atayan: ${task.assignedByDisplayName}',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              Text(
                'Bitiş Tarihi: ${_formatDate(task.dueDate)}',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              Text(
                'Durum: ${_getStatusText(task.status)}',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              Text(
                'Zorluk Derecesi: ${task.difficultyLevel} (${_getDifficultyText(task.difficultyLevel)})',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              if (task.userCompletionNote != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Tamamlanma Notu: ${task.userCompletionNote}',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
              if (task.captainEvaluation != null && task.captainRating != null) ...[
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Kaptan Değerlendirmesi: ',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getRatingColor(task.captainRating!).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getRatingText(task.captainRating!),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getRatingColor(task.captainRating!),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        task.captainEvaluation!,
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
              if (task.adminScore != null)
                Text(
                  'Puan: ${task.adminScore}',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat', style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.assigned:
        return AppColors.info;
      case TaskStatus.inProgress:
        return AppColors.primary;
      case TaskStatus.completedByUser:
        return AppColors.warning;
      case TaskStatus.evaluatedByCaptain:
        return Colors.orange;
      case TaskStatus.evaluatedByAdmin:
        return AppColors.success;
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.assigned:
        return 'Bekliyor';
      case TaskStatus.inProgress:
        return 'Devam Ediyor';
      case TaskStatus.completedByUser:
        return 'Tamamlandı';
      case TaskStatus.evaluatedByCaptain:
        return 'Onaylandı';
      case TaskStatus.evaluatedByAdmin:
        return 'Puanlandı';
    }
  }

  Color _getRatingColor(CaptainRating rating) {
    switch (rating) {
      case CaptainRating.good:
        return AppColors.success;
      case CaptainRating.medium:
        return AppColors.warning;
      case CaptainRating.bad:
        return AppColors.error;
    }
  }

  String _getRatingText(CaptainRating rating) {
    switch (rating) {
      case CaptainRating.good:
        return 'İyi';
      case CaptainRating.medium:
        return 'Orta';
      case CaptainRating.bad:
        return 'Kötü';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _getDifficultyText(int level) {
    switch (level) {
      case 1:
        return 'Kolay';
      case 2:
        return 'Orta';
      case 3:
        return 'Zor';
      default:
        return 'Bilinmiyor';
    }
  }
}