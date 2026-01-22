import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      final weekStart = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 7));
      final monthStart = DateTime(now.year, now.month, 1);
      final yearStart = DateTime(now.year, 1, 1);

      // Kullanıcının tüm görevlerini al
      final tasks =
      await _taskService.getTasksAssignedToUser(widget.user.uid).first;
      _allTasks = tasks;

      int weekly = 0;
      int monthly = 0;
      int yearly = 0;

      for (var task in tasks) {
        // Sadece puanlanmış görevleri hesapla
        if (task.status == TaskStatus.evaluatedByAdmin &&
            task.adminScore != null) {
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
        startDate = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 7));
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
      if (task.status == TaskStatus.evaluatedByAdmin &&
          task.adminScore != null) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
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
                  color: isDark
                      ? AppColors.darkPrimary.withOpacity(0.2)
                      : Colors.deepPurple.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.task_alt_rounded,
                      color: isDark ? AppColors.darkPrimary : Colors.deepPurple,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Görev Listesi
              if (tasks.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: 64,
                            color: isDark ? AppColors.darkTextSecondary : Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Bu dönemde puanlanmış görev bulunmamaktadır.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : Colors.grey,
                            ),
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
                      final score =
                      (task.adminScore! * task.difficultyLevel).toInt();
                      final taskDate = task.completedAt ?? task.updatedAt;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: isDark ? 4 : 2,
                        color: isDark ? AppColors.darkCardBackground : Colors.white,
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
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.green.shade900.withOpacity(0.3)
                                          : Colors.green.shade100,
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
                                            color: isDark
                                                ? Colors.green.shade300
                                                : Colors.green.shade900,
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
                                    color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade700,
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
                                    color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    taskDate != null
                                        ? DateFormat('dd MMMM yyyy HH:mm', 'tr_TR')
                                        .format(taskDate)
                                        : 'Tarih belirtilmemiş',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
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
                                    color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Zorluk: ${task.difficultyLevel}x | Yönetici Puanı: ${task.adminScore}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              // Drive Link butonu
                              if (task.driveLink != null &&
                                  task.driveLink!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _launchURL(task.driveLink!),
                                    icon: const Icon(Icons.cloud, size: 16),
                                    label: const Text('Drive\'da Görüntüle'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isDark ? AppColors.darkPrimary : Colors.blue,
                                      side: BorderSide(
                                        color: isDark ? AppColors.darkPrimary : Colors.blue,
                                        width: 1,
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text('${widget.user.displayName} - Görev Sonuçları'),
        backgroundColor: isDark ? AppColors.darkCardBackground : AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Puan İstatistikleri Kartı
          Card(
            margin: const EdgeInsets.all(16.0),
            elevation: isDark ? 6 : 4,
            color: isDark ? AppColors.darkCardBackground : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.analytics_rounded,
                        color: isDark ? AppColors.darkPrimary : Colors.deepPurple,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Puan İstatistikleri',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Divider(
                    height: 24,
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                  if (_isLoadingStats)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          color: isDark ? AppColors.darkPrimary : AppColors.primary,
                        ),
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
                          backgroundColor: isDark
                              ? Colors.amber.shade900.withOpacity(0.2)
                              : Colors.amber.shade50,
                          period: 'total',
                        ),
                        const SizedBox(height: 12),

                        // Yıllık Puan
                        _buildScoreRow(
                          icon: Icons.calendar_today_rounded,
                          iconColor: Colors.green,
                          label: 'Yıllık Puan (${DateTime.now().year})',
                          score: _yearlyScore,
                          backgroundColor: isDark
                              ? Colors.green.shade900.withOpacity(0.2)
                              : Colors.green.shade50,
                          period: 'yearly',
                        ),
                        const SizedBox(height: 12),

                        // Aylık Puan
                        _buildScoreRow(
                          icon: Icons.trending_up_rounded,
                          iconColor: Colors.blueAccent,
                          label: 'Aylık Puan (${_getMonthName(DateTime.now().month)})',
                          score: _monthlyScore,
                          backgroundColor: isDark
                              ? Colors.blue.shade900.withOpacity(0.2)
                              : Colors.blue.shade50,
                          period: 'monthly',
                        ),
                        const SizedBox(height: 12),

                        // Haftalık Puan
                        _buildScoreRow(
                          icon: Icons.date_range_rounded,
                          iconColor: Colors.orange,
                          label: 'Haftalık Puan (Son 7 Gün)',
                          score: _weeklyScore,
                          backgroundColor: isDark
                              ? Colors.orange.shade900.withOpacity(0.2)
                              : Colors.orange.shade50,
                          period: 'weekly',
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Görevler Listesi Başlığı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.assignment_turned_in_rounded,
                  color: isDark ? AppColors.darkPrimary : Colors.deepPurple,
                ),
                const SizedBox(width: 8),
                Text(
                  'Görevler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
                  return Center(
                    child: CircularProgressIndicator(
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Hata: ${snapshot.error}',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      '${widget.user.displayName} için görev bulunamadı.',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Görev kartını oluşturur
  Widget _buildTaskCard(TaskModel task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(task.status);
    final evaluated = task.status == TaskStatus.evaluatedByAdmin;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 4 : 2,
      color: isDark ? AppColors.darkCardBackground : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          iconColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          collapsedIconColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          title: Text(
            task.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
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
                  ? (isDark ? Colors.green.shade300 : AppColors.success)
                  : Colors.red,
            ),
          )
              : Icon(
            Icons.keyboard_arrow_down,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Açıklama: ${task.description}',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Son Teslim: ${DateFormat('dd MMMM yyyy', 'tr_TR').format(task.dueDate)}',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (task.userCompletionNote != null &&
                      task.userCompletionNote!.isNotEmpty)
                    _buildNoteSection(
                        'Kullanıcı Notu', task.userCompletionNote!, Colors.blue),
                  // Drive Link bölümü
                  if (task.driveLink != null && task.driveLink!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Drive Dökümanı',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkPrimary : Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _launchURL(task.driveLink!),
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('Drive bağlantısını kopyala'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? AppColors.darkPrimary : Colors.blue,
                                side: BorderSide(
                                  color: isDark ? AppColors.darkPrimary : Colors.blue,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (task.captainEvaluation != null &&
                      task.captainEvaluation!.isNotEmpty)
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
                      isDark ? Colors.green.shade300 : AppColors.success,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Not bölümünü oluşturur
  Widget _buildNoteSection(String title, String content, Color color,
      {CaptainRating? rating}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              color: color.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                if (rating != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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

  // URL açma fonksiyonu
  Future<void> _launchURL(String url) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Link panoya kopyalandı! Tarayıcınızda açabilirsiniz.'),
            backgroundColor: AppColors.info,
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

  /// Görev durumuna göre renk döndürür
  Color _getStatusColor(TaskStatus status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (status) {
      case TaskStatus.assigned:
      case TaskStatus.inProgress:
        return isDark ? Colors.blue.shade300 : Colors.blue;
      case TaskStatus.completedByUser:
        return isDark ? Colors.orange.shade300 : Colors.orange;
      case TaskStatus.evaluatedByCaptain:
        return isDark ? Colors.purple.shade300 : Colors.purple;
      case TaskStatus.evaluatedByAdmin:
        return isDark ? Colors.green.shade300 : AppColors.success;
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