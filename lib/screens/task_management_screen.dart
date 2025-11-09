import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';


class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen> {
  final UserService _userService = UserService();
  final TaskService _taskService = TaskService();
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
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

  // Görev atama dialogunu göster
  Future<void> _showAssignTaskDialog() async {
    // Önce teamId kontrolü yap
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bilgisi alınamadı.')),
      );
      return;
    }

    if (_currentUser!.isCaptain && (_currentUser!.teamId == null || _currentUser!.teamId!.isEmpty)) {
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
              title: const Text('Yeni Görev Ata'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Görev Başlığı'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Görev Açıklaması'),
                      maxLines: 3,
                    ),
                    ListTile(
                      title: Text(selectedDueDate == null
                          ? 'Son Teslim Tarihi Seç'
                          : 'Son Teslim Tarihi: ${selectedDueDate!.day}.${selectedDueDate!.month}.${selectedDueDate!.year}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
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
                    // Görev atanacak kullanıcı seçimi
                    StreamBuilder<List<UserModel>>(
                      stream: _currentUser!.isAdmin
                          ? _userService.getAllUsers()
                          : _userService.getTeamMembers(_currentUser!.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Hata: ${snapshot.error}');
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text('Görev atanacak kullanıcı bulunamadı.');
                        }

                        List<UserModel> assignableUsers = snapshot.data!;
                        // Kaptan kendi ekibindeki kaptanlara görev atayamaz, sadece üyelere.
                        // Yönetici ise herkese atayabilir.
                        if (_currentUser!.isCaptain) {
                          assignableUsers = assignableUsers.where((user) => user.isUser).toList();
                        }

                        return DropdownButtonFormField<UserModel>(
                          decoration: const InputDecoration(labelText: 'Görev Atanacak Kişi'),
                          value: selectedUser,
                          onChanged: (UserModel? newValue) {
                            setState(() {
                              selectedUser = newValue;
                            });
                          },
                          items: assignableUsers.map<DropdownMenuItem<UserModel>>((UserModel user) {
                            return DropdownMenuItem<UserModel>(
                              value: user,
                              child: Text('${user.displayName} (${user.roleDisplayName})'),
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

                    if (_currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kullanıcı bilgisi alınamadı.')),
                      );
                      return;
                    }

                    final newTask = TaskModel(
                      id: '', // Firestore tarafından atanacak
                      title: titleController.text,
                      description: descriptionController.text,
                      assignedToUid: selectedUser!.uid,
                      assignedToDisplayName: selectedUser!.displayName,
                      assignedByUid: _currentUser!.uid,
                      assignedByDisplayName: _currentUser!.displayName,
                      dueDate: selectedDueDate!,
                      createdAt: DateTime.now(),
                      status: TaskStatus.assigned,
                    );

                    await _taskService.createTask(newTask);
                    Navigator.pop(context);
                  },
                  child: const Text('Görev Ata'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Görev tamamlama dialogu (Üyeler için)
  Future<void> _showCompleteTaskDialog(TaskModel task) async {
    final TextEditingController completionNoteController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Görevi Tamamla'),
          content: TextField(
            controller: completionNoteController,
            decoration: const InputDecoration(labelText: 'Yaptığınız işi açıklayın'),
            maxLines: 5,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (completionNoteController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen görevi nasıl tamamladığınızı açıklayın.')),
                  );
                  return;
                }
                await _taskService.completeTask(task.id, completionNoteController.text);
                Navigator.pop(context);
              },
              child: const Text('Tamamla'),
            ),
          ],
        );
      },
    );
  }

  // Kaptan değerlendirme dialogu
  Future<void> _showCaptainEvaluationDialog(TaskModel task) async {
    String? selectedEvaluation;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Kaptan Değerlendirmesi'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Görev: ${task.title}'),
                  Text('Açıklama: ${task.description}'),
                  Text('Üye Notu: ${task.userCompletionNote ?? 'Yok'}'),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Değerlendirme'),
                    value: selectedEvaluation,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedEvaluation = newValue;
                      });
                    },
                    items: const [
                      DropdownMenuItem(value: 'İyi', child: Text('İyi')),
                      DropdownMenuItem(value: 'Orta', child: Text('Orta')),
                      DropdownMenuItem(value: 'Kötü', child: Text('Kötü')),
                    ],
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
                    if (selectedEvaluation == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lütfen bir değerlendirme seçin.')),
                      );
                      return;
                    }
                    await _taskService.evaluateTaskByCaptain(task.id, selectedEvaluation!);
                    Navigator.pop(context);
                  },
                  child: const Text('Değerlendir'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Yönetici puanlama dialogu
  Future<void> _showAdminScoringDialog(TaskModel task) async {
    int? selectedScore;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Yönetici Puanlaması'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Görev: ${task.title}'),
                  Text('Açıklama: ${task.description}'),
                  Text('Üye Notu: ${task.userCompletionNote ?? 'Yok'}'),
                  Text('Kaptan Değerlendirmesi: ${task.captainEvaluation ?? 'Yok'}'),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Puan (0-10)'),
                    value: selectedScore,
                    onChanged: (int? newValue) {
                      setState(() {
                        selectedScore = newValue;
                      });
                    },
                    items: List.generate(11, (index) => index).map<DropdownMenuItem<int>>((int score) {
                      return DropdownMenuItem<int>(
                        value: score,
                        child: Text(score.toString()),
                      );
                    }).toList(),
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
                    if (selectedScore == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lütfen bir puan seçin.')),
                      );
                      return;
                    }
                    await _taskService.evaluateTaskByAdmin(task.id, selectedScore!);

                    // Puanlar güncellendikten sonra kullanıcının toplam ve aylık skorunu güncelle
                    final assignedUser = await _userService.getUser(task.assignedToUid);
                    if (assignedUser != null) {
                      final currentMonthKey = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
                      Map<String, int> updatedMonthlyScores = Map.from(assignedUser.monthlyScores);
                      updatedMonthlyScores.update(
                        currentMonthKey,
                            (value) => value + selectedScore!,
                        ifAbsent: () => selectedScore!,
                      );
                      await _userService.updateUserScores(
                        assignedUser.uid,
                        assignedUser.totalScore + selectedScore!,
                        updatedMonthlyScores,
                      );
                    }

                    Navigator.pop(context);
                  },
                  child: const Text('Puanla'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}.${date.month}.${date.year}";
  }

  String _getTaskStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.assigned:
        return 'Atandı';
      case TaskStatus.completedByUser:
        return 'Üye Tarafından Tamamlandı';
      case TaskStatus.evaluatedByCaptain:
        return 'Kaptan Tarafından Değerlendirildi';
      case TaskStatus.evaluatedByAdmin:
        return 'Yönetici Tarafından Puanlandı';
    }
  }

  // Stream'i güvenli bir şekilde al
  Stream<List<TaskModel>> _getTaskStream() {
    if (_currentUser == null) {
      return Stream.value([]);
    }

    if (_currentUser!.isAdmin) {
      return _taskService.getTasksForAdmin();
    } else if (_currentUser!.isCaptain) {
      // Kaptan için teamId kontrolü
      final teamId = _currentUser!.teamId;
      if (teamId == null || teamId.isEmpty) {
        return Stream.value([]);
      }
      return _taskService.getTasksForCaptainEvaluation(teamId);
    } else {
      // Üye için
      return _taskService.getTasksAssignedToUser(_currentUser!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Görev Yönetimi'),
      ),
      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<TaskModel>>(
        stream: _getTaskStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          // Kaptan için özel mesaj
          if (_currentUser!.isCaptain && (_currentUser!.teamId == null || _currentUser!.teamId!.isEmpty)) {
            return const Center(
              child: Text('Takım bilgisi bulunamadı. Lütfen yöneticinizle iletişime geçin.'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Henüz görev bulunmamaktadır.'));
          }

          final tasks = snapshot.data!;

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(task.description),
                      const SizedBox(height: 8),
                      Text('Atanan Kişi: ${task.assignedToDisplayName}'),
                      Text('Atayan Kişi: ${task.assignedByDisplayName}'),
                      Text('Son Teslim Tarihi: ${_formatDate(task.dueDate)}'),
                      Text('Durum: ${_getTaskStatusText(task.status)}'),
                      if (task.userCompletionNote != null) Text('Üye Notu: ${task.userCompletionNote}'),
                      if (task.captainEvaluation != null) Text('Kaptan Değerlendirmesi: ${task.captainEvaluation}'),
                      if (task.adminScore != null) Text('Yönetici Puanı: ${task.adminScore}'),
                      const SizedBox(height: 8),

                      // Üye için görev tamamlama butonu
                      if (_currentUser!.isUser && task.status == TaskStatus.assigned)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: ElevatedButton(
                            onPressed: () => _showCompleteTaskDialog(task),
                            child: const Text('Görevi Tamamla'),
                          ),
                        ),

                      // Kaptan için görev değerlendirme butonu
                      if (_currentUser!.isCaptain && task.status == TaskStatus.completedByUser)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: ElevatedButton(
                            onPressed: () => _showCaptainEvaluationDialog(task),
                            child: const Text('Değerlendir'),
                          ),
                        ),

                      // Yönetici için görev puanlama butonu
                      if (_currentUser!.isAdmin && task.status == TaskStatus.evaluatedByCaptain)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: ElevatedButton(
                            onPressed: () => _showAdminScoringDialog(task),
                            child: const Text('Puanla'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: (_currentUser != null && (_currentUser!.isAdmin || _currentUser!.isCaptain))
          ? FloatingActionButton(
        onPressed: _showAssignTaskDialog,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}