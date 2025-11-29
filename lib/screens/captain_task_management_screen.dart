import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/colors.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';
import '../services/team_service.dart'; // ✅ YENİ: TeamService eklendi
import 'package:intl/intl.dart';

class CaptainTaskManagementScreen extends StatefulWidget {
  const CaptainTaskManagementScreen({super.key});

  @override
  State<CaptainTaskManagementScreen> createState() => _CaptainTaskManagementScreenState();
}

class _CaptainTaskManagementScreenState extends State<CaptainTaskManagementScreen> {
  final TaskService _taskService = TaskService();
  final TeamService _teamService = TeamService(); // ✅ YENİ: TeamService eklendi
  CaptainRating? _selectedRating; // ✅ YENİ: Seçilen dereceyi tutmak için
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildSegmentedControl(),
              Expanded(
                child: _buildCurrentPage(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTaskDialog,
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label: const Text('Görev Ata'),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Görev Yönetimi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Kaptan Paneli',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.blue),
                SizedBox(width: 4),
                Text(
                  'Kaptan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(child: _buildSegmentButton(0, 'Bana Atanan', Icons.assignment_ind)),
          const SizedBox(width: 8),
          Expanded(child: _buildSegmentButton(1, 'Değerlendirme', Icons.rate_review)),
          const SizedBox(width: 8),
          Expanded(child: _buildSegmentButton(2, 'Takım Görevleri', Icons.people)),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(int index, String label, IconData icon) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : AppColors.border,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildMyTasksPage();
      case 1:
        return _buildEvaluationTasksPage();
      case 2:
        return _buildTeamTasksPage();
      default:
        return _buildMyTasksPage();
    }
  }

  Widget _buildMyTasksPage() {
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
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inbox,
            title: 'Henüz görev yok',
            subtitle: 'Size atanan görevler burada görünecek',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            return _buildTaskCard(tasks[index]);
          },
        );
      },
    );
  }

  Widget _buildEvaluationTasksPage() {
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
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            title: 'Değerlendirilecek görev yok',
            subtitle: 'Ekip üyelerinin tamamladığı görevler burada görünecek',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            return _buildEvaluationTaskCard(tasks[index]);
          },
        );
      },
    );
  }

  Widget _buildTeamTasksPage() {
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
          return Center(child: Text('Hata: ${teamSnapshot.error}'));
        }

        final teamMembers = teamSnapshot.data ?? [];

        if (teamMembers.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_outline,
            title: 'Takım üyesi yok',
            subtitle: 'Takımınıza üye eklendiğinde görevleri burada görünecek',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: teamMembers.length,
          itemBuilder: (context, index) {
            return _buildTeamMemberCard(teamMembers[index]);
          },
        );
      },
    );
  }

  Widget _buildTaskCard(TaskModel task, {bool showEditButton = true}) {
    Color statusColor = _getStatusColor(task.status);
    String statusText = _getStatusText(task.status);
    bool canComplete = task.status == TaskStatus.assigned;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
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
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Atayan: ${task.assignedByDisplayName}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(task.dueDate),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                // ✅ Düzenlenme bilgisi
                if (task.updatedAt != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 14, color: Colors.blue),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Düzenlendi: ${_formatDateTime(task.updatedAt!)}${task.updatedBy != null ? ' - ${task.updatedBy}' : ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // ✅ Düzenleme ve Tamamlama butonları
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
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
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
    _selectedRating = null; // Diyalog açıldığında seçimi sıfırla

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Görevi Değerlendir'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Derece Seçin:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
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
                      decoration: const InputDecoration(
                        labelText: 'Değerlendirme Notu',
                        hintText: 'Görev hakkındaki değerlendirmenizi yazın...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
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
                      _selectedRating!, // Seçilen dereceyi gönder
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
                    backgroundColor: Colors.blue,
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
        color = Colors.green;
        text = 'İyi';
        break;
      case CaptainRating.medium:
        color = Colors.orange;
        text = 'Orta';
        break;
      case CaptainRating.bad:
        color = Colors.red;
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

  Widget _buildEvaluationTaskCard(TaskModel task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        task.assignedToDisplayName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
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
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (task.userCompletionNote != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.note, size: 16, color: AppColors.textPrimary),
                        SizedBox(width: 4),
                        Text(
                          'Tamamlanma Notu:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.userCompletionNote!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
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
                      backgroundColor: Colors.blue,
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

  Widget _buildTeamMemberCard(UserModel member) {
    bool isExpanded = false;

    return StatefulBuilder(
      builder: (context, setStateCard) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
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
                              colors: [Colors.blue.shade400, Colors.blue.shade600],
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                member.email,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.stars, size: 14, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Puan: ${member.totalScore}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildMemberTasks(member),
                ),
            ],
          ),
        );
      },
    );
  }

  // captain_task_management_screen.dart dosyasındaki _buildMemberTasks metodunu güncelleyin:

  Widget _buildMemberTasks(UserModel member) {
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
          return Text('Hata: ${snapshot.error}');
        }

        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Bu üyeye henüz görev atanmamış',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          children: tasks.map((task) {
            // ✅ Kaptanın oluşturduğu görevleri kontrol et
            bool isCreatedByCaptain = task.assignedByUid == _currentUser?.uid;
            bool canEdit = isCreatedByCaptain && task.status == TaskStatus.assigned;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Bitiş: ${_formatDate(task.dueDate)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  // ✅ Düzenlenme bilgisi
                  if (task.updatedAt != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 12, color: Colors.blue),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Düzenlendi: ${_formatDateTime(task.updatedAt!)}${task.updatedBy != null ? ' - ${task.updatedBy}' : ''}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.blue,
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
                                foregroundColor: Colors.blue,
                                side: const BorderSide(color: Colors.blue),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // ✅ Sil butonu
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
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.border),
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
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // YENİ: Görev oluşturma dialogu
  Future<void> _showCreateTaskDialog() async {
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

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Takıma Görev Ata'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Görev Başlığı',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Görev Açıklaması',
                        border: OutlineInputBorder(),
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
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          locale: const Locale('tr', 'TR'), // Türkçe yerel ayar ekle
                        );
                        if (picked != null && picked != selectedDueDate) {
                          setState(() {
                            selectedDueDate = picked;
                          });
                        }
                      },
                    ),
                    StreamBuilder<List<UserModel>>(
                      stream: _userService.getTeamMembers(_currentUser!.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Hata: ${snapshot.error}');
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text('Görev atanacak takım üyesi bulunamadı.');
                        }

                        List<UserModel> assignableUsers = snapshot.data!
                            .where((user) => user.isUser)
                            .toList();

                        if (assignableUsers.isEmpty) {
                          return const Text('Takımınızda görev atanabilecek üye yok.');
                        }

                        return DropdownButtonFormField<UserModel>(
                          decoration: const InputDecoration(
                            labelText: 'Görev Atanacak Takım Üyesi',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedUser,
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
                  child: const Text('İptal'),
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

                    // Atanan kullanıcının takım bilgilerini çek
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
                      assignedToTeamId: assignedUserTeamId, // ✅ YENİ: Takım ID'si eklendi
                      assignedToTeamName: assignedUserTeamName, // ✅ YENİ: Takım Adı eklendi
                      assignedByUid: _currentUser!.uid,
                      assignedByDisplayName: _currentUser!.displayName,
                      dueDate: selectedDueDate!,
                      createdAt: DateTime.now(),
                      status: TaskStatus.assigned,
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
                    backgroundColor: Colors.blue,
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Görevi Tamamla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Tamamlanma Notu',
                hintText: 'Görev hakkında notlarınızı yazın...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
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
            child: const Text('Tamamla'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditTaskDialog(TaskModel task) async {
    final TextEditingController titleController = TextEditingController(text: task.title);
    final TextEditingController descriptionController = TextEditingController(text: task.description);
    DateTime selectedDueDate = task.dueDate;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Görevi Düzenle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Görev Başlığı',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Görev Açıklaması',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Son Teslim: ${selectedDueDate.day}.${selectedDueDate.month}.${selectedDueDate.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
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
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.edit, size: 16, color: Colors.blue),
                                SizedBox(width: 4),
                                Text(
                                  'Son Düzenleme:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatDateTime(task.updatedAt!)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (task.updatedBy != null)
                              Text(
                                'Düzenleyen: ${task.updatedBy}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
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
                  child: const Text('İptal'),
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
                    backgroundColor: Colors.blue,
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

// 2. Tarih ve saat formatlama
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _rejectTask(TaskModel task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Görevi Reddet'),
        content: const Text(
          'Bu görev reddedilecek ve kullanıcıya geri gönderilecek. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
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
            ),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );
  }
  Future<void> _deleteTask(String taskId, String taskTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            SizedBox(width: 12),
            Text('Görevi Sil'),
          ],
        ),
        content: const Text(
          'Bu görevi silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz ve görevle ilgili tüm veriler silinecektir.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Açıklama: ${task.description}'),
              const SizedBox(height: 8),
              Text('Atayan: ${task.assignedByDisplayName}'),
              Text('Bitiş Tarihi: ${_formatDate(task.dueDate)}'),
              Text('Durum: ${_getStatusText(task.status)}'),
              if (task.userCompletionNote != null) ...[
                const SizedBox(height: 8),
                Text('Tamamlanma Notu: ${task.userCompletionNote}'),
              ],
              if (task.captainEvaluation != null && task.captainRating != null) ...[
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Kaptan Değerlendirmesi: ',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
              if (task.adminScore != null) Text('Puan: ${task.adminScore}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
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
        return AppColors.primary; // Veya uygun bir renk
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
}