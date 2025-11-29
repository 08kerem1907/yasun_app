import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:user_role_management/models/task_model.dart';
import 'package:user_role_management/models/user_model.dart';
import 'package:user_role_management/services/task_service.dart';
import 'package:user_role_management/constants/colors.dart'; // Renkler için varsayılan import

class GorevSonuclariScreen extends StatefulWidget {
  final UserModel user;

  const GorevSonuclariScreen({super.key, required this.user});

  @override
  State<GorevSonuclariScreen> createState() => _GorevSonuclariScreenState();
}

class _GorevSonuclariScreenState extends State<GorevSonuclariScreen> {
  final TaskService _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.assigned:
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completedByUser:
        return Colors.orange;
      case TaskStatus.evaluatedByCaptain:
        return Colors.purple;
      case TaskStatus.evaluatedByAdmin:
        return AppColors.success;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.assigned:
        return 'Atandı';
      case TaskStatus.inProgress:
        return 'Devam Ediyor';
      case TaskStatus.completedByUser:
        return 'Kullanıcı Tamamladı';
      case TaskStatus.evaluatedByCaptain:
        return 'Kaptan Değerlendirdi';
      case TaskStatus.evaluatedByAdmin:
        return 'Yönetici Puanladı';
      default:
        return 'Bilinmiyor';
    }
  }

  Color _getRatingColor(CaptainRating rating) {
    switch (rating) {
      case CaptainRating.good:
        return Colors.green;
      case CaptainRating.medium:
        return Colors.orange;
      case CaptainRating.bad:
        return Colors.red;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.user.displayName} - Görev Sonuçları'),
      ),
      body: StreamBuilder<List<TaskModel>>(
        // TaskService'e bir kullanıcının tüm görevlerini çeken bir fonksiyon ekleyeceğiz.
        // Şimdilik varsayımsal olarak getTasksAssignedToUser kullanıyorum.
        stream: _taskService.getTasksAssignedToUser(widget.user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('${widget.user.displayName} için tamamlanmış görev bulunamadı.'),
            );
          }

          final tasks = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _buildTaskCard(task);
            },
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final statusColor = _getStatusColor(task.status);
    final evaluated = task.status == TaskStatus.evaluatedByAdmin;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Durum: ${_getStatusText(task.status)}',
          style: TextStyle(color: statusColor, fontSize: 12),
        ),
        trailing: evaluated
            ? Text(
                'Puan: ${task.adminScore ?? '-'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: task.adminScore != null && task.adminScore! >= 80 ? AppColors.success : Colors.red,
                ),
              )
            : const Icon(Icons.keyboard_arrow_down),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Açıklama: ${task.description}'),
                const SizedBox(height: 8),
                Text('Son Teslim: ${DateFormat('dd MMMM yyyy', 'tr_TR').format(task.dueDate)}'),
                const SizedBox(height: 8),
                if (task.userCompletionNote != null && task.userCompletionNote!.isNotEmpty)
                  _buildNoteSection('Kullanıcı Notu', task.userCompletionNote!, Colors.blue),
                if (task.captainEvaluation != null && task.captainEvaluation!.isNotEmpty)
                  _buildNoteSection(
                    'Kaptan Değerlendirmesi',
                    '${task.captainEvaluation!}\nDerece: ${task.captainRating != null ? _getRatingText(task.captainRating!) : 'Belirtilmemiş'}',
                    Colors.purple,
                    rating: task.captainRating,
                  ),
                if (evaluated)
                  _buildNoteSection(
                    'Yönetici Puanı',
                    'Puan: ${task.adminScore ?? '-'}',
                    AppColors.success,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSection(String title, String content, Color color, {CaptainRating? rating}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(content),
                if (rating != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRatingColor(rating).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getRatingText(rating),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
