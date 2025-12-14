import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:user_role_management/models/task_model.dart';
import 'package:user_role_management/models/user_model.dart';
import 'package:user_role_management/services/task_service.dart';
import 'package:user_role_management/constants/colors.dart';

class GorevSonuclariScreen extends StatefulWidget {
  final UserModel user;

  const GorevSonuclariScreen({super.key, required this.user});

  @override
  State<GorevSonuclariScreen> createState() => _GorevSonuclariScreenState();
}

class _GorevSonuclariScreenState extends State<GorevSonuclariScreen> {
  final TaskService _taskService = TaskService();

  /// Puan istatistikleri
  int _weeklyScore = 0;
  int _monthlyScore = 0;
  int _yearlyScore = 0;
  bool _isLoadingStats = true;

  /// Tüm görevleri cache'leme
  List<TaskModel> _allTasks = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
    _calculateScores();
  }

  /// Haftalık, aylık ve yıllık puanları hesapla
  Future<void> _calculateScores() async {
    try {
      final now = DateTime.now();

      // Tarih aralıkları
      final weekStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
      final monthStart = DateTime(now.year, now.month, 1);
      final yearStart = DateTime(now.year, 1, 1);

      // Kullanıcının tüm görevlerini al
      final tasks = await _taskService.getTasksAssignedToUser(widget.user.uid).first;
      _allTasks = tasks;

      int weekly = 0;
      int monthly = 0;
      int yearly = 0;

      for (var task in tasks) {
        // Sadece puanlanmış görevleri hesapla
        if (task.status == TaskStatus.evaluatedByAdmin && task.adminScore != null) {
          final score = (task.adminScore! * task.difficultyLevel).toInt();

          // Görevin tamamlanma tarihi
          DateTime? taskDate = task.completedAt ?? task.updatedAt;

          if (taskDate != null) {
            if (taskDate.isAfter(weekStart)) {
              weekly += score;
            }
            if (taskDate.isAfter(monthStart)) {
              monthly += score;
            }
            if (taskDate.isAfter(yearStart)) {
              yearly += score;
            }
          }
        }
      }

      setState(() {
        _weeklyScore = weekly;
        _monthlyScore = monthly;
        _yearlyScore = yearly;
        _isLoadingStats = false;
      });
    } catch (e) {
      debugPrint('Puan hesaplama hatası: $e');
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  /// Belirli bir döneme ait görevleri filtrele
  List<TaskModel> _filterTasksByPeriod(String period) {
    final now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case 'weekly':
        startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
        break;
      case 'monthly':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'yearly':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        return [];
    }

    // Puanlanmış görevleri filtrele
    List<TaskModel> filteredTasks = _allTasks.where((task) {
      if (task.status == TaskStatus.evaluatedByAdmin && task.adminScore != null) {
        DateTime? taskDate = task.completedAt ?? task.updatedAt;
        if (taskDate != null && taskDate.isAfter(startDate)) {
          return true;
        }
      }
      return false;
    }).toList();

    // Kronolojik sıralama (en yeniden en eskiye)
    filteredTasks.sort((a, b) {
      DateTime? dateA = a.completedAt ?? a.updatedAt;
      DateTime? dateB = b.completedAt ?? b.updatedAt;

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateB.compareTo(dateA);
    });

    return filteredTasks;
  }

  /// Görev listesini dialog olarak göster
  void _showTasksDialog(String period, String title) {
    final tasks = _filterTasksByPeriod(period);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Başlığı
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.task_alt_rounded, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Görev Listesi
              if (tasks.isEmpty)
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_rounded, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Bu dönemde puanlanmış görev bulunmamaktadır.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final score = (task.adminScore! * task.difficultyLevel).toInt();
                      final taskDate = task.completedAt ?? task.updatedAt;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
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
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Colors.amber,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$score puan',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (task.description.isNotEmpty)
                                Text(
                                  task.description,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    taskDate != null
                                        ? DateFormat('dd MMMM yyyy HH:mm', 'tr_TR').format(taskDate)
                                        : 'Tarih belirtilmemiş',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.speed_rounded,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Zorluk: ${task.difficultyLevel}x | Yönetici Puanı: ${task.adminScore}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.user.displayName} - Görev Sonuçları'),
      ),
      body: Column(
        children: [
          // Puan İstatistikleri Kartı
          Card(
            margin: const EdgeInsets.all(16.0),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.analytics_rounded, color: Colors.deepPurple, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Puan İstatistikleri',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  if (_isLoadingStats)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    Column(
                      children: [
                        // Toplam Puan
                        _buildScoreRow(
                          icon: Icons.military_tech_rounded,
                          iconColor: Colors.amber,
                          label: 'Toplam Puan',
                          score: widget.user.totalScore,
                          backgroundColor: Colors.amber.shade50,
                          period: 'total',
                        ),
                        const SizedBox(height: 12),

                        // Yıllık Puan
                        _buildScoreRow(
                          icon: Icons.calendar_today_rounded,
                          iconColor: Colors.green,
                          label: 'Yıllık Puan (${DateTime.now().year})',
                          score: _yearlyScore,
                          backgroundColor: Colors.green.shade50,
                          period: 'yearly',
                        ),
                        const SizedBox(height: 12),

                        // Aylık Puan
                        _buildScoreRow(
                          icon: Icons.trending_up_rounded,
                          iconColor: Colors.blueAccent,
                          label: 'Aylık Puan (${_getMonthName(DateTime.now().month)})',
                          score: _monthlyScore,
                          backgroundColor: Colors.blue.shade50,
                          period: 'monthly',
                        ),
                        const SizedBox(height: 12),

                        // Haftalık Puan
                        _buildScoreRow(
                          icon: Icons.date_range_rounded,
                          iconColor: Colors.orange,
                          label: 'Haftalık Puan (Son 7 Gün)',
                          score: _weeklyScore,
                          backgroundColor: Colors.orange.shade50,
                          period: 'weekly',
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Görevler Listesi Başlığı
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.assignment_turned_in_rounded, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'Görevler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Görev Listesi
          Expanded(
            child: StreamBuilder<List<TaskModel>>(
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
                    child: Text('${widget.user.displayName} için görev bulunamadı.'),
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
          ),
        ],
      ),
    );
  }

  /// Puan satırı widget'ı (tıklanabilir)
  Widget _buildScoreRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required int score,
    required Color backgroundColor,
    String? period,
  }) {
    return InkWell(
      onTap: period != null && period != 'total'
          ? () {
        String title = '';
        switch (period) {
          case 'weekly':
            title = 'Haftalık Görevler (Son 7 Gün)';
            break;
          case 'monthly':
            title = 'Aylık Görevler (${_getMonthName(DateTime.now().month)})';
            break;
          case 'yearly':
            title = 'Yıllık Görevler (${DateTime.now().year})';
            break;
        }
        _showTasksDialog(period, title);
      }
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              score.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            if (period != null && period != 'total')
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.arrow_forward_ios_rounded, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  /// Görev kartını oluşturur
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
          'Nihai Puan: ${(task.adminScore ?? 0) * task.difficultyLevel}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: task.adminScore != null && task.adminScore! >= 80
                ? AppColors.success
                : Colors.red,
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
                    'Verilen Puan: ${task.adminScore ?? '-'}\nZorluk Katsayısı: ${task.difficultyLevel}\nNihai Puan: ${(task.adminScore ?? 0) * task.difficultyLevel}',
                    AppColors.success,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Not bölümünü oluşturur
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

  /// Görev durumuna göre renk döndürür
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

  /// Görev durumuna göre metin döndürür
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

  /// Derece rengini döndürür
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

  /// Derece metnini döndürür
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

  /// Ay adını döndürür
  String _getMonthName(int month) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return months[month - 1];
  }
}
