import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';

class ScoreTableScreen extends StatefulWidget {
  const ScoreTableScreen({super.key});

  @override
  State<ScoreTableScreen> createState() => _ScoreTableScreenState();
}

class _ScoreTableScreenState extends State<ScoreTableScreen> {
  final UserService _userService = UserService();
  final TaskService _taskService = TaskService();
  UserModel? _currentUser;
  String _filterType = 'my_tasks';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      UserModel? user = await _userService.getUser(firebaseUser.uid);
      setState(() {
        _currentUser = user;
      });
    }
  }

  Color _getScoreColor(int? score) {
    if (score == null) return Colors.grey;
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getScoreIcon(int? score) {
    if (score == null) return Icons.help_outline;
    if (score >= 80) return Icons.star;
    if (score >= 60) return Icons.star_half;
    return Icons.star_border;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Görev Sonuçları',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _FilterChip(
                    label: 'Görevlerim',
                    icon: Icons.person,
                    isSelected: _filterType == 'my_tasks',
                    onTap: () {
                      setState(() {
                        _filterType = 'my_tasks';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FilterChip(
                    label: 'Takımım',
                    icon: Icons.groups,
                    isSelected: _filterType == 'team_tasks',
                    onTap: () {
                      setState(() {
                        _filterType = 'team_tasks';
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<TaskModel>>(
              stream: _taskService.getAllEvaluatedTasks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _EmptyState(
                    icon: Icons.error_outline,
                    message: 'Bir hata oluştu',
                    color: Colors.red,
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _EmptyState(
                    icon: Icons.assignment_outlined,
                    message: 'Değerlendirilmiş görev bulunamadı',
                  );
                }

                List<TaskModel> allTasks = snapshot.data!;
                List<TaskModel> filteredTasks;

                if (_filterType == 'my_tasks') {
                  filteredTasks = allTasks
                      .where((task) => task.assignedToUid == _currentUser!.uid)
                      .toList();
                } else {
                  filteredTasks = allTasks;
                }

                if (filteredTasks.isEmpty) {
                  return _EmptyState(
                    icon: Icons.filter_list_off,
                    message: 'Bu filtreye uygun görev bulunamadı',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    TaskModel task = filteredTasks[index];
                    return _TaskCard(
                      task: task,
                      scoreColor: _getScoreColor(task.adminScore),
                      scoreIcon: _getScoreIcon(task.adminScore),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final Color scoreColor;
  final IconData scoreIcon;

  const _TaskCard({
    required this.task,
    required this.scoreColor,
    required this.scoreIcon,
  });

  @override
  Widget build(BuildContext context) {
    final completedDate = task.completedAt != null
        ? DateFormat('dd/MM/yyyy').format(task.completedAt!)
        : 'Tamamlanmadı';
    final evaluatedDate = task.adminEvaluatedAt != null
        ? DateFormat('dd/MM/yyyy').format(task.adminEvaluatedAt!)
        : 'Beklemede';

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(scoreIcon, color: scoreColor, size: 24),
                const SizedBox(height: 2),
                Text(
                  '${task.adminScore ?? '-'}',
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          title: Text(
            task.title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.assignedToDisplayName,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          children: [
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.flag_outlined,
              label: 'Durum',
              value: _getStatusText(task.status),
              valueColor: _getStatusColor(task.status),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.check_circle_outline,
              label: 'Tamamlanma',
              value: completedDate,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.assessment_outlined,
              label: 'Değerlendirme',
              value: evaluatedDate,
            ),
            if (task.userCompletionNote != null &&
                task.userCompletionNote!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _NoteSection(
                icon: Icons.note_alt_outlined,
                title: 'Kullanıcı Notu',
                content: task.userCompletionNote!,
                color: Colors.blue,
              ),
            ],
            if (task.captainEvaluation != null &&
                task.captainEvaluation!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _NoteSection(
                icon: Icons.verified_user_outlined,
                title: 'Kaptan Değerlendirmesi',
                content: task.captainEvaluation!,
                color: Colors.purple,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusText(TaskStatus status) {
    final statusName = status.name.toLowerCase();

    if (statusName.contains('evaluatedbyadmin') || statusName.contains('yönetici')) {
      return 'Yönetici Tarafından Değerlendirildi';
    } else if (statusName.contains('completed') || statusName.contains('tamamlan')) {
      return 'Tamamlandı';
    } else if (statusName.contains('pending') || statusName.contains('bekle')) {
      return 'Beklemede';
    } else if (statusName.contains('progress') || statusName.contains('devam')) {
      return 'Devam Ediyor';
    } else if (statusName.contains('approved') || statusName.contains('onayla')) {
      return 'Onaylandı';
    } else if (statusName.contains('rejected') || statusName.contains('red')) {
      return 'Reddedildi';
    } else if (statusName.contains('assigned') || statusName.contains('atand')) {
      return 'Atandı';
    }
    return status.name;
  }

  Color _getStatusColor(TaskStatus status) {
    // TaskStatus enum değerlerinize göre ayarlayın
    final statusName = status.name.toLowerCase();

    if (statusName.contains('evaluatedbyadmin') || statusName.contains('yönetici')) {
      return Colors.purple;
    } else if (statusName.contains('completed') || statusName.contains('tamamlan')) {
      return Colors.green;
    } else if (statusName.contains('pending') || statusName.contains('bekle')) {
      return Colors.orange;
    } else if (statusName.contains('progress') || statusName.contains('devam')) {
      return Colors.blue;
    }
    return Colors.grey;
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: valueColor ?? Colors.grey[800],
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _NoteSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color color;

  const _NoteSection({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color? color;

  const _EmptyState({
    required this.icon,
    required this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: (color ?? Colors.grey).withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}