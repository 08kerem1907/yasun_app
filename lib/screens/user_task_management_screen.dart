import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/colors.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';

class TaskManagementNavigator extends InheritedWidget {
  final Function(int) changeTab;

  const TaskManagementNavigator({
    super.key,
    required this.changeTab,
    required super.child,
  });

  static TaskManagementNavigator? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TaskManagementNavigator>();
  }

  @override
  bool updateShouldNotify(TaskManagementNavigator oldWidget) => false;
}

class UserTaskManagementScreen extends StatefulWidget {
  final int initialTab;

  const UserTaskManagementScreen({super.key, this.initialTab = 0});

  @override
  State<UserTaskManagementScreen> createState() =>
      _UserTaskManagementScreenState();
}

class _UserTaskManagementScreenState extends State<UserTaskManagementScreen> {
  final TaskService _taskService = TaskService();
  final UserService _userService = UserService();
  UserModel? _currentUser;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    try {
      User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        UserModel? user = await _userService.getUser(firebaseUser.uid);
        if (mounted) setState(() => _currentUser = user);
      }
    } catch (e) {
      print('Hata: $e');
    }
  }

  void _changeTab(int index) {
    if (_selectedIndex != index) setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TaskManagementNavigator(
      changeTab: _changeTab,
      child: Scaffold(
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
                Expanded(child: _buildCurrentPage(colorScheme, textTheme)),
              ],
            ),
          ),
        ),
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
                  'Görevlerim',
                  style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
                Text(
                  'Size atanan görevler',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (_currentUser != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, size: 16, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    '${_currentUser!.totalScore}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
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
              child: _buildSegmentButton(
                  0, 'Aktif Görevler', Icons.assignment, colorScheme, textTheme)),
          const SizedBox(width: 12),
          Expanded(
              child: _buildSegmentButton(1, 'Tamamlananlar', Icons.check_circle,
                  colorScheme, textTheme)),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(int index, String label, IconData icon,
      ColorScheme colorScheme, TextTheme textTheme) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outline,
              width: 1),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 24,
                color: isSelected ? Colors.white : colorScheme.onSurfaceVariant),
            const SizedBox(height: 6),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : colorScheme.onSurfaceVariant),
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
        return _buildActiveTasksPage(colorScheme, textTheme);
      case 1:
        return _buildCompletedTasksPage(colorScheme, textTheme);
      default:
        return _buildActiveTasksPage(colorScheme, textTheme);
    }
  }

  Widget _buildActiveTasksPage(ColorScheme colorScheme, TextTheme textTheme) {
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
              child: Text('Hata: ${snapshot.error}',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurface)));
        }

        final allTasks = snapshot.data ?? [];
        final activeTasks = allTasks
            .where((task) =>
        task.status == TaskStatus.assigned ||
            task.status == TaskStatus.inProgress ||
            task.status == TaskStatus.completedByUser ||
            task.status == TaskStatus.evaluatedByCaptain)
            .toList();

        if (activeTasks.isEmpty) {
          return _buildEmptyState(
            icon: Icons.task_alt,
            title: 'Aktif görev yok',
            subtitle: 'Yeni görevler atandığında burada görünecek',
            textTheme: textTheme,
            colorScheme: colorScheme,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activeTasks.length,
          itemBuilder: (context, index) =>
              _buildActiveTaskCard(activeTasks[index], colorScheme, textTheme),
        );
      },
    );
  }

  Widget _buildCompletedTasksPage(
      ColorScheme colorScheme, TextTheme textTheme) {
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
              child: Text('Hata: ${snapshot.error}',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurface)));
        }

        final allTasks = snapshot.data ?? [];
        final completedTasks = allTasks
            .where((task) => task.status == TaskStatus.evaluatedByAdmin)
            .toList();

        if (completedTasks.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            title: 'Tamamlanan görev yok',
            subtitle: 'Puanlanan görevler burada görünecek',
            textTheme: textTheme,
            colorScheme: colorScheme,
          );
        }

        int totalScore = completedTasks
            .where((task) => task.adminScore != null)
            .fold(0, (sum, task) => sum + task.adminScore!);

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.8)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(Icons.assignment_turned_in, 'Tamamlanan',
                      '${completedTasks.length}'),
                  Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.3)),
                  _buildStatItem(Icons.stars, 'Toplam Puan', '$totalScore'),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: completedTasks.length,
                itemBuilder: (context, index) => _buildCompletedTaskCard(
                    completedTasks[index], colorScheme, textTheme),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTaskCard(
      TaskModel task, ColorScheme colorScheme, TextTheme textTheme) {
    Color statusColor = _getStatusColor(task.status);
    String statusText = _getStatusText(task.status);
    bool canStart = task.status == TaskStatus.assigned;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showTaskDetails(task),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(task.title,
                          style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        statusText,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Atayan: ${task.assignedByDisplayName}',
                      style: textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const Spacer(),
                    Icon(
                      _isOverdue(task.dueDate)
                          ? Icons.warning
                          : Icons.calendar_today,
                      size: 16,
                      color: _isOverdue(task.dueDate)
                          ? AppColors.error
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(task.dueDate),
                      style: TextStyle(
                        fontSize: 13,
                        color: _isOverdue(task.dueDate)
                            ? AppColors.error
                            : colorScheme.onSurfaceVariant,
                        fontWeight: _isOverdue(task.dueDate)
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                if (canStart) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _startTask(task),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Görevi Gördüm, Başlıyorum'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
                if (task.status == TaskStatus.inProgress) ...[
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
                if (task.status == TaskStatus.completedByUser) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_empty,
                            size: 16, color: AppColors.info),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kaptan değerlendirmesi bekleniyor...',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (task.status == TaskStatus.evaluatedByCaptain) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pending,
                            size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Yönetici puanlaması bekleniyor...',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildCompletedTaskCard(
      TaskModel task, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.1),
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
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 24,
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
                        'Tamamlandı: ${_formatDate(task.adminEvaluatedAt ?? DateTime.now())}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade400, Colors.amber.shade600],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${task.adminScore ?? 0}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(title,
              style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _showTaskDetails(TaskModel task) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title,
                        style: textTheme.headlineSmall
                            ?.copyWith(color: colorScheme.onSurface)),
                    const SizedBox(height: 16),
                    Text(task.description,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Text(
                        'Zorluk Derecesi: ${task.difficultyLevel} (${_getDifficultyText(task.difficultyLevel)})',
                        style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface)),
                    const SizedBox(height: 16),
                    if (task.userCompletionNote != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text('Tamamlama Notu: ${task.userCompletionNote}',
                            style: textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurface)),
                      ),
                    if (task.captainEvaluation != null &&
                        task.captainRating != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Kaptan Değerlendirmesi: ',
                                  style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getRatingColor(task.captainRating!)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getRatingText(task.captainRating!),
                                  style: textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                      _getRatingColor(task.captainRating!),
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0, bottom: 16),
                            child: Text(task.captainEvaluation!,
                                style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant)),
                          ),
                        ],
                      ),
                    if (task.adminScore != null) ...[
                      Text('Verilen Puan: ${task.adminScore}',
                          style: textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurface)),
                      const SizedBox(height: 4),
                      Text(
                          'Nihai Puan: ${task.adminScore! * task.difficultyLevel} (${task.adminScore} x ${task.difficultyLevel})',
                          style: textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurface)),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _startTask(TaskModel task) async {
    try {
      await _taskService.startTask(task.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Görev durumu "Çalışılıyor" olarak güncellendi.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görev başlatılırken hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showCompleteTaskDialog(TaskModel task) {
    final noteController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text('Görevi Tamamla',
              style: TextStyle(color: colorScheme.onSurface)),
          content: TextField(
            controller: noteController,
            decoration: InputDecoration(
              labelText: 'Tamamlama Notu',
              labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary),
              ),
            ),
            style: TextStyle(color: colorScheme.onSurface),
            maxLines: 3,
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
                  await _taskService.completeTask(task.id, noteController.text);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Görev tamamlandı olarak işaretlendi.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
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
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tamamla'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _isOverdue(DateTime dueDate) {
    return DateTime.now().isAfter(dueDate);
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.assigned:
        return AppColors.primary;
      case TaskStatus.inProgress:
        return AppColors.textSecondary;
      case TaskStatus.completedByUser:
        return AppColors.info;
      case TaskStatus.evaluatedByCaptain:
        return Colors.orange;
      case TaskStatus.evaluatedByAdmin:
        return AppColors.success;
      default:
        return AppColors.textSecondary;
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
  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.assigned:
        return 'Atandı';
      case TaskStatus.inProgress:
        return 'Çalışılıyor';
      case TaskStatus.completedByUser:
        return 'Tamamlandı (Kaptan Bekliyor)';
      case TaskStatus.evaluatedByCaptain:
        return 'Kaptan Değerlendirdi (Admin Bekliyor)';
      case TaskStatus.evaluatedByAdmin:
        return 'Puanlandı';
      default:
        return 'Bilinmiyor';
    }
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