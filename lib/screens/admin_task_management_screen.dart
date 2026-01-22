import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';
import 'package:flutter/services.dart';

class AdminTaskManagementScreen extends StatefulWidget {
  final int initialTabIndex;

  const AdminTaskManagementScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<AdminTaskManagementScreen> createState() =>
      _AdminTaskManagementScreenState();
}

class _AdminTaskManagementScreenState extends State<AdminTaskManagementScreen> {
  final TaskService _taskService = TaskService();
  final UserService _userService = UserService();
  UserModel? _currentUser;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
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
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Görev'),
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
                  'Yönetici Paneli',
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
                Icon(Icons.admin_panel_settings,
                    size: 16, color: colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Admin',
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
          Expanded(
              child: _buildSegmentButton(0, 'Bana Atanan', Icons.assignment_ind,
                  colorScheme, textTheme)),
          const SizedBox(width: 8),
          Expanded(
              child: _buildSegmentButton(1, 'Değerlendirme', Icons.rate_review,
                  colorScheme, textTheme)),
          const SizedBox(width: 8),
          Expanded(
              child: _buildSegmentButton(
                  2, 'Tüm Görevler', Icons.assignment, colorScheme, textTheme)),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(int index, String label, IconData icon,
      ColorScheme colorScheme, TextTheme textTheme) {
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
          color: isSelected ? colorScheme.primary : colorScheme.surface,
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
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
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
        return _buildAllTasksPage(colorScheme, textTheme);
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text('Hata: ${snapshot.error}',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurface)),
              ],
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
            return _buildTaskCard(tasks[index],
                showActions: true,
                isMyTask: true,
                colorScheme: colorScheme,
                textTheme: textTheme);
          },
        );
      },
    );
  }

  Widget _buildEvaluationTasksPage(
      ColorScheme colorScheme, TextTheme textTheme) {
    return StreamBuilder<List<TaskModel>>(
      stream: _taskService.getTasksForAdminEvaluation(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text('Hata: ${snapshot.error}',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurface)),
              ],
            ),
          );
        }

        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            title: 'Değerlendirilecek görev yok',
            subtitle: 'Kaptan onayından geçen görevler burada görünecek',
            colorScheme: colorScheme,
            textTheme: textTheme,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            return _buildEvaluationTaskCard(
                tasks[index], colorScheme, textTheme);
          },
        );
      },
    );
  }

  String _getTeamName(String teamId, List<TaskModel> tasks) {
    if (teamId == 'Bilinmeyen Takım') return teamId;

    final taskWithTeamName = tasks.firstWhere(
          (task) =>
      task.assignedToTeamId == teamId && task.assignedToTeamName != null,
      orElse: () => tasks.firstWhere(
            (task) => task.assignedToTeamId == teamId,
        orElse: () => TaskModel(
          id: '',
          title: '',
          description: '',
          assignedToUid: '',
          assignedToDisplayName: '',
          assignedByUid: '',
          assignedByDisplayName: '',
          dueDate: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      ),
    );
    return taskWithTeamName.assignedToTeamName ?? teamId;
  }

  void _showSnackBar(String message, ColorScheme colorScheme,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildAllTasksPage(ColorScheme colorScheme, TextTheme textTheme) {
    return StreamBuilder<List<TaskModel>>(
      stream: _taskService.getTasksForAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text('Hata: ${snapshot.error}',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurface)),
              ],
            ),
          );
        }

        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return _buildEmptyState(
            icon: Icons.assignment,
            title: 'Henüz görev oluşturulmamış',
            subtitle: 'Yeni görev eklemek için + butonuna tıklayın',
            colorScheme: colorScheme,
            textTheme: textTheme,
          );
        }

        // Görevleri takımlara göre grupla
        final Map<String, List<TaskModel>> groupedTasks = {};
        for (var task in tasks) {
          final teamId = task.assignedToTeamId ?? 'Bilinmeyen Takım';
          if (!groupedTasks.containsKey(teamId)) {
            groupedTasks[teamId] = [];
          }
          groupedTasks[teamId]!.add(task);
        }

        // Her takım içindeki görevleri sırala
        groupedTasks.forEach((teamId, taskList) {
          taskList.sort((a, b) {
            final dateComparison = a.createdAt.compareTo(b.createdAt);
            if (dateComparison != 0) return dateComparison;
            return a.dueDate.compareTo(b.dueDate);
          });
        });

        // Takımları alfabetik olarak sırala
        final sortedTeamIds = groupedTasks.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedTeamIds.length,
          itemBuilder: (context, index) {
            final teamId = sortedTeamIds[index];
            final teamTasks = groupedTasks[teamId]!;
            final teamName = _getTeamName(teamId, teamTasks);
            final taskCount = teamTasks.length;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ExpansionTile(
                tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  teamName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                subtitle: Text(
                  '$taskCount Görev',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                children: teamTasks
                    .map((task) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: _buildTaskCard(task,
                      showActions: true,
                      colorScheme: colorScheme,
                      textTheme: textTheme),
                ))
                    .toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTaskCard(TaskModel task,
      {required bool showActions,
        bool isMyTask = false,
        required ColorScheme colorScheme,
        required TextTheme textTheme}) {
    Color statusColor = _getStatusColor(task.status, colorScheme);
    String statusText = _getStatusText(task.status);

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
          onTap: () => _showTaskDetails(task, colorScheme, textTheme),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
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
                    Icon(Icons.person_outline,
                        size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      task.assignedToDisplayName,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.calendar_today,
                        size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(task.dueDate),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                // ✅ YENİ: Drive Link Bölümü
                if (task.driveLink != null && task.driveLink!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud, size: 14, color: Colors.blue),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Drive Dökümanı mevcut',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _launchURL(task.driveLink!),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Kopyala',
                              style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                ],
                if (task.adminScore != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Nihai Puan: ${task.adminScore! * task.difficultyLevel} (${task.adminScore} × ${task.difficultyLevel})',
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
                if (task.updatedAt != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit,
                            size: 14, color: colorScheme.secondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Düzenlendi: ${_formatDateTime(task.updatedAt!)}${task.updatedBy != null ? ' - ${task.updatedBy}' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (showActions) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isMyTask && task.status == TaskStatus.assigned)
                        TextButton.icon(
                          onPressed: () => _showCompleteTaskDialog(
                              task, colorScheme, textTheme),
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: const Text('Tamamla'),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                          ),
                        )
                      else
                        TextButton.icon(
                          onPressed: () =>
                              _showEditTaskDialog(task, colorScheme, textTheme),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Düzenle'),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                          ),
                        ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _deleteTask(
                            task.id, task.title, colorScheme, textTheme),
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Sil'),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEvaluationTaskCard(
      TaskModel task, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border:
        Border.all(color: colorScheme.tertiary.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: colorScheme.tertiary.withOpacity(0.1),
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
                    color: colorScheme.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.rate_review, color: colorScheme.tertiary),
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
                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kullanıcı Notu:',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
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
            // ✅ YENİ: Drive Link Bölümü
            if (task.driveLink != null && task.driveLink!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.cloud, size: 16, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          'Google Drive Dökümanı:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _launchURL(task.driveLink!),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Drive bağlantısını kopyala'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (task.captainEvaluation != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          'Kaptan Değerlendirmesi:',
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (task.captainRating != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getRatingColor(
                                  task.captainRating!, colorScheme)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getRatingText(task.captainRating!),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getRatingColor(
                                    task.captainRating!, colorScheme),
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.captainEvaluation!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showScoreDialog(task, colorScheme, textTheme),
                icon: const Icon(Icons.rate_review),
                label: const Text('Puanla ve Onayla'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
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
            style: textTheme.titleMedium?.copyWith(
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
    if (_currentUser == null) {
      _showSnackBar(
          'Kullanıcı bilgisi alınamadı.', Theme.of(context).colorScheme,
          isError: true);
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;

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
              title: Text('Yeni Görev Ata',
                  style: TextStyle(color: colorScheme.onSurface)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Görev Başlığı',
                        labelStyle:
                        TextStyle(color: colorScheme.onSurfaceVariant),
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
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
                        labelStyle:
                        TextStyle(color: colorScheme.onSurfaceVariant),
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
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
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                      trailing: Icon(Icons.calendar_today,
                          color: colorScheme.onSurfaceVariant),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate:
                          DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate:
                          DateTime.now().add(const Duration(days: 365)),
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
                      style: TextStyle(color: colorScheme.onSurface),
                      dropdownColor: colorScheme.surface,
                      decoration: InputDecoration(
                        labelText: 'Zorluk Derecesi',
                        labelStyle:
                        TextStyle(color: colorScheme.onSurfaceVariant),
                        border: const OutlineInputBorder(),
                        helperText: 'Puan bu değerle çarpılacaktır',
                        helperStyle:
                        TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      value: selectedDifficulty,
                      onChanged: (int? newValue) {
                        setState(() {
                          selectedDifficulty = newValue ?? 1;
                        });
                      },
                      items: const [
                        DropdownMenuItem<int>(
                            value: 1, child: Text('1 - Kolay')),
                        DropdownMenuItem<int>(
                            value: 2, child: Text('2 - Orta')),
                        DropdownMenuItem<int>(value: 3, child: Text('3 - Zor')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<List<UserModel>>(
                      stream: _userService.getAllUsers(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Hata: ${snapshot.error}',
                              style: TextStyle(color: colorScheme.onSurface));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Text('Görev atanacak kullanıcı bulunamadı.',
                              style: TextStyle(color: colorScheme.onSurface));
                        }

                        List<UserModel> assignableUsers = snapshot.data!;

                        return DropdownButtonFormField<UserModel>(
                          style: TextStyle(color: colorScheme.onSurface),
                          dropdownColor: colorScheme.surface,
                          decoration: InputDecoration(
                            labelText: 'Görev Atanacak Kişi',
                            labelStyle:
                            TextStyle(color: colorScheme.onSurfaceVariant),
                            border: const OutlineInputBorder(),
                          ),
                          value: selectedUser,
                          onChanged: (UserModel? newValue) {
                            setState(() {
                              selectedUser = newValue;
                            });
                          },
                          items: assignableUsers
                              .map<DropdownMenuItem<UserModel>>(
                                  (UserModel user) {
                                return DropdownMenuItem<UserModel>(
                                  value: user,
                                  child: Text(
                                      '${user.displayName} (${user.roleDisplayName})'),
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
                  child: Text('İptal',
                      style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty ||
                        descriptionController.text.isEmpty ||
                        selectedDueDate == null ||
                        selectedUser == null) {
                      _showSnackBar(
                          'Lütfen tüm alanları doldurun.', colorScheme,
                          isError: true);
                      return;
                    }

                    final newTask = TaskModel(
                      id: '',
                      title: titleController.text,
                      description: descriptionController.text,
                      assignedToUid: selectedUser!.uid,
                      assignedToDisplayName: selectedUser!.displayName,
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
                      _showSnackBar(
                          'Görev başarıyla oluşturuldu!', colorScheme);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
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

  Future<void> _showEditTaskDialog(
      TaskModel task, ColorScheme colorScheme, TextTheme textTheme) async {
    final TextEditingController titleController =
    TextEditingController(text: task.title);
    final TextEditingController descriptionController =
    TextEditingController(text: task.description);
    DateTime selectedDueDate = task.dueDate;
    int selectedDifficulty = task.difficultyLevel;
    UserModel? selectedUser;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: colorScheme.surface,
              title: Text('Görevi Düzenle',
                  style: TextStyle(color: colorScheme.onSurface)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Görev Başlığı',
                        labelStyle:
                        TextStyle(color: colorScheme.onSurfaceVariant),
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
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
                        labelStyle:
                        TextStyle(color: colorScheme.onSurfaceVariant),
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
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
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                      trailing: Icon(Icons.calendar_today,
                          color: colorScheme.onSurfaceVariant),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDueDate,
                          firstDate: DateTime.now(),
                          lastDate:
                          DateTime.now().add(const Duration(days: 365)),
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
                      style: TextStyle(color: colorScheme.onSurface),
                      dropdownColor: colorScheme.surface,
                      decoration: InputDecoration(
                        labelText: 'Zorluk Derecesi',
                        labelStyle:
                        TextStyle(color: colorScheme.onSurfaceVariant),
                        border: const OutlineInputBorder(),
                        helperText: 'Puan bu değerle çarpılacaktır',
                        helperStyle:
                        TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      value: selectedDifficulty,
                      onChanged: (int? newValue) {
                        setState(() {
                          selectedDifficulty = newValue ?? 1;
                        });
                      },
                      items: const [
                        DropdownMenuItem<int>(
                            value: 1, child: Text('1 - Kolay')),
                        DropdownMenuItem<int>(
                            value: 2, child: Text('2 - Orta')),
                        DropdownMenuItem<int>(value: 3, child: Text('3 - Zor')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<List<UserModel>>(
                      stream: _userService.getAllUsers(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Hata: ${snapshot.error}',
                              style: TextStyle(color: colorScheme.onSurface));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Text('Kullanıcı bulunamadı.',
                              style: TextStyle(color: colorScheme.onSurface));
                        }

                        List<UserModel> assignableUsers = snapshot.data!;

                        if (selectedUser == null) {
                          selectedUser = assignableUsers.firstWhere(
                                (user) => user.uid == task.assignedToUid,
                            orElse: () => assignableUsers.first,
                          );
                        }

                        return DropdownButtonFormField<UserModel>(
                          style: TextStyle(color: colorScheme.onSurface),
                          dropdownColor: colorScheme.surface,
                          decoration: InputDecoration(
                            labelText: 'Görev Atanacak Kişi',
                            labelStyle:
                            TextStyle(color: colorScheme.onSurfaceVariant),
                            border: const OutlineInputBorder(),
                          ),
                          value: selectedUser,
                          onChanged: (UserModel? newValue) {
                            setState(() {
                              selectedUser = newValue;
                            });
                          },
                          items: assignableUsers
                              .map<DropdownMenuItem<UserModel>>(
                                  (UserModel user) {
                                return DropdownMenuItem<UserModel>(
                                  value: user,
                                  child: Text(
                                      '${user.displayName} (${user.roleDisplayName})'),
                                );
                              }).toList(),
                        );
                      },
                    ),
                    if (task.updatedAt != null) ...[
                      const Divider(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.edit,
                                    size: 16, color: colorScheme.secondary),
                                const SizedBox(width: 4),
                                Text(
                                  'Son Düzenleme:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(task.updatedAt!),
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (task.updatedBy != null)
                              Text(
                                'Düzenleyen: ${task.updatedBy}',
                                style: TextStyle(
                                  fontSize: 11,
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
                  child: Text('İptal',
                      style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty ||
                        descriptionController.text.isEmpty ||
                        selectedUser == null) {
                      _showSnackBar(
                          'Lütfen tüm alanları doldurun.', colorScheme,
                          isError: true);
                      return;
                    }

                    await _taskService.updateTaskWithInfo(
                      task.id,
                      titleController.text,
                      descriptionController.text,
                      selectedDueDate,
                      _currentUser!.displayName,
                      difficultyLevel: selectedDifficulty,
                      assignedToUid: selectedUser!.uid,
                      assignedToDisplayName: selectedUser!.displayName,
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      _showSnackBar(
                          'Görev başarıyla güncellendi!', colorScheme);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
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

  void _showCompleteTaskDialog(
      TaskModel task, ColorScheme colorScheme, TextTheme textTheme) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text('Görevi Tamamla',
              style: TextStyle(color: colorScheme.onSurface)),
          content: TextField(
            controller: noteController,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Tamamlama Notu',
              labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              border: const OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colorScheme.primary),
              ),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('İptal',
                  style: TextStyle(color: colorScheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              onPressed: () async {
                await _taskService.completeTaskByAdmin(
                    task.id, noteController.text);
                Navigator.of(context).pop();
                _showSnackBar('Görev tamamlandı!', colorScheme);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: const Text('Onayla'),
            ),
          ],
        );
      },
    );
  }

  void _showTaskDetails(
      TaskModel task, ColorScheme colorScheme, TextTheme textTheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(task.title, style: TextStyle(color: colorScheme.onSurface)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Açıklama: ${task.description}',
                  style: TextStyle(color: colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text('Atanan: ${task.assignedToDisplayName}',
                  style: TextStyle(color: colorScheme.onSurface)),
              Text('Bitiş Tarihi: ${_formatDate(task.dueDate)}',
                  style: TextStyle(color: colorScheme.onSurface)),
              Text('Durum: ${_getStatusText(task.status)}',
                  style: TextStyle(color: colorScheme.onSurface)),
              Text(
                  'Zorluk Derecesi: ${task.difficultyLevel} (${_getDifficultyText(task.difficultyLevel)})',
                  style: TextStyle(color: colorScheme.onSurface)),
              if (task.adminScore != null)
                Text('Verilen Puan: ${task.adminScore}',
                    style: TextStyle(color: colorScheme.onSurface)),
              if (task.adminScore != null)
                Text(
                    'Nihai Puan: ${task.adminScore! * task.difficultyLevel} (${task.adminScore} × ${task.difficultyLevel})',
                    style: TextStyle(color: colorScheme.onSurface)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat',
                style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  void _showScoreDialog(
      TaskModel task, ColorScheme colorScheme, TextTheme textTheme) {
    final scoreController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text('Görevi Puanla',
            style: TextStyle(color: colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zorluk Derecesi: ${task.difficultyLevel} (${_getDifficultyText(task.difficultyLevel)})',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nihai puan = Verilen puan × ${task.difficultyLevel}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: scoreController,
              style: TextStyle(color: colorScheme.onSurface),
              keyboardType: TextInputType.number,
              maxLength: 3,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  final intValue = int.tryParse(value);
                  if (intValue != null && intValue > 100) {
                    scoreController.text = '100';
                    scoreController.selection = TextSelection.fromPosition(
                      TextPosition(offset: scoreController.text.length),
                    );
                  }
                }
              },
              decoration: InputDecoration(
                labelText: 'Puan (0-100)',
                labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                hintText: '85',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
                prefixIcon:
                Icon(Icons.stars, color: colorScheme.onSurfaceVariant),
                helperText: 'Lütfen 0 ile 100 arasında bir değer girin',
                helperStyle: TextStyle(color: colorScheme.onSurfaceVariant),
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
              final scoreText = scoreController.text.trim();

              if (scoreText.isEmpty) {
                _showSnackBar('Lütfen bir puan girin', colorScheme,
                    isError: true);
                return;
              }

              final score = int.tryParse(scoreText);

              if (score == null) {
                _showSnackBar('Lütfen geçerli bir sayı girin', colorScheme,
                    isError: true);
                return;
              }

              if (score < 0 || score > 100) {
                _showSnackBar('Puan 0 ile 100 arasında olmalıdır', colorScheme,
                    isError: true);
                return;
              }

              await _taskService.evaluateTaskByAdmin(task.id, score);
              final finalScore = score * task.difficultyLevel;
              if (context.mounted) {
                Navigator.pop(context);
                _showSnackBar(
                    'Görev başarıyla puanlandı! Verilen puan: $score, Nihai puan: $finalScore',
                    colorScheme);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('Puanla'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Link panoya kopyalandı! Tarayıcınızda açabilirsiniz.'),
            backgroundColor: Colors.blue,
            action: SnackBarAction(
              label: 'Tamam',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Link açma hatası: $e');
    }
  }

  Future<void> _deleteTask(String taskId, String taskTitle,
      ColorScheme colorScheme, TextTheme textTheme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: colorScheme.error, size: 28),
            const SizedBox(width: 12),
            Text('Görevi Sil', style: TextStyle(color: colorScheme.onSurface)),
          ],
        ),
        content: Text(
          'Bu görevi silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz ve görevle ilgili tüm veriler silinecektir.',
          style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal',
                style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
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
          _showSnackBar('Görev başarıyla silindi', colorScheme);
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Hata: $e', colorScheme, isError: true);
        }
      }
    }
  }

  Color _getStatusColor(TaskStatus status, ColorScheme colorScheme) {
    switch (status) {
      case TaskStatus.assigned:
        return colorScheme.tertiary;
      case TaskStatus.inProgress:
        return colorScheme.primary;
      case TaskStatus.completedByUser:
        return Colors.orange;
      case TaskStatus.evaluatedByCaptain:
        return Colors.deepOrange;
      case TaskStatus.evaluatedByAdmin:
        return colorScheme.primary;
    }
  }

  Color _getRatingColor(CaptainRating rating, ColorScheme colorScheme) {
    switch (rating) {
      case CaptainRating.good:
        return Colors.green;
      case CaptainRating.medium:
        return Colors.orange;
      case CaptainRating.bad:
        return colorScheme.error;
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

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.assigned:
        return 'Atandı';
      case TaskStatus.inProgress:
        return 'Devam Ediyor';
      case TaskStatus.completedByUser:
        return 'Tamamlandı';
      case TaskStatus.evaluatedByCaptain:
        return 'Kaptan Onayladı';
      case TaskStatus.evaluatedByAdmin:
        return 'Puanlandı';
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
