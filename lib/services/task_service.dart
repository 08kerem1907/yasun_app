import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import 'user_service.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  // ============================================
  // PRIVATE HELPER METHODS
  // ============================================

  /// Kullanıcının rolünü getir
  Future<String?> _getUserRole(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        return userDoc.data()!['role'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Kullanıcı rolü alınırken hata: $e');
      return null;
    }
  }

  /// Görev silme aktivitesini kaydet
  Future<void> _logTaskDeletion(
      String taskId,
      String deletedByName,
      String taskTitle,
      ) async {
    try {
      await _firestore.collection('task_activities').add({
        'type': 'taskDeleted',
        'taskId': taskId,
        'taskTitle': taskTitle,
        'deletedBy': deletedByName,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('❌ Görev silme aktivitesi kaydedilirken hata: $e');
    }
  }

  /// Görev düzenleme aktivitesini kaydet
  Future<void> _logTaskEdit(
      String taskId,
      String editedByName,
      String taskTitle,
      ) async {
    try {
      await _firestore.collection('task_activities').add({
        'type': 'taskEdited',
        'taskId': taskId,
        'taskTitle': taskTitle,
        'editedBy': editedByName,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('❌ Görev düzenleme aktivitesi kaydedilirken hata: $e');
    }
  }

  /// Kullanıcı puanını güncelle (aylık ve toplam)
  Future<void> _updateUserScore(String userId, int scoreToAdd) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        debugPrint('❌ Kullanıcı bulunamadı: $userId');
        return;
      }

      final user = UserModel.fromFirestore(userDoc);
      final now = DateTime.now();
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final newTotalScore = user.totalScore + scoreToAdd;
      final currentMonthlyScore = user.monthlyScores[monthKey] ?? 0;
      final newMonthlyScore = currentMonthlyScore + scoreToAdd;

      final updatedMonthlyScores = Map<String, int>.from(user.monthlyScores);
      updatedMonthlyScores[monthKey] = newMonthlyScore;

      await _firestore.collection('users').doc(userId).update({
        'totalScore': newTotalScore,
        'monthlyScores': updatedMonthlyScores,
      });
    } catch (e) {
      debugPrint('❌ Kullanıcı puanı güncellenirken hata: $e');
    }
  }

  /// Liste sıralama helper fonksiyonu
  List<TaskModel> _sortTasksByDate(
      List<TaskModel> tasks, {
        bool descending = true,
      }) {
    tasks.sort((a, b) => descending
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));
    return tasks;
  }

  // ============================================
  // ADMIN OPERATIONS
  // ============================================

  /// Admin için değerlendirme bekleyen görevler
  Stream<List<TaskModel>> getTasksForAdminEvaluation() {
    return _firestore
        .collection('tasks')
        .where('status', isEqualTo: TaskStatus.evaluatedByCaptain.name)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();

      // Client-side sorting
      tasks.sort((a, b) {
        if (a.captainEvaluatedAt == null && b.captainEvaluatedAt == null) {
          return 0;
        }
        if (a.captainEvaluatedAt == null) return 1;
        if (b.captainEvaluatedAt == null) return -1;
        return b.captainEvaluatedAt!.compareTo(a.captainEvaluatedAt!);
      });

      return tasks;
    });
  }

  /// Admin için tüm görevleri getir
  Stream<List<TaskModel>> getTasksForAdmin() {
    return _firestore.collection('tasks').snapshots().map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
      return _sortTasksByDate(tasks);
    });
  }

  /// Tüm değerlendirilmiş görevleri getir
  Stream<List<TaskModel>> getAllEvaluatedTasks() {
    return _firestore
        .collection('tasks')
        .where('status', whereIn: [
      TaskStatus.evaluatedByAdmin.name,
      TaskStatus.evaluatedByCaptain.name,
    ])
        .orderBy('adminEvaluatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TaskModel.fromFirestore(doc))
        .toList());
  }

  /// Admin değerlendirmesi (limitli)
  Stream<List<TaskModel>> getTasksForAdminEvaluationLimited({
    int limit = 50,
  }) {
    return _firestore
        .collection('tasks')
        .where('status', isEqualTo: TaskStatus.evaluatedByCaptain.name)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();

      tasks.sort((a, b) {
        if (a.captainEvaluatedAt == null && b.captainEvaluatedAt == null) {
          return 0;
        }
        if (a.captainEvaluatedAt == null) return 1;
        if (b.captainEvaluatedAt == null) return -1;
        return b.captainEvaluatedAt!.compareTo(a.captainEvaluatedAt!);
      });

      return tasks;
    });
  }

  /// Admin puanlar ve kullanıcının puanını günceller
  Future<void> evaluateTaskByAdmin(String taskId, int adminScore) async {
    try {
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) {
        debugPrint('❌ Görev bulunamadı: $taskId');
        return;
      }

      final task = TaskModel.fromFirestore(taskDoc);

      await _firestore.collection('tasks').doc(taskId).update({
        'status': TaskStatus.evaluatedByAdmin.name,
        'adminScore': adminScore,
        'adminEvaluatedAt': Timestamp.now(),
      });

      // Zorluk derecesi ile çarpılmış nihai puan
      final finalScore = adminScore * task.difficultyLevel;
      await _updateUserScore(task.assignedToUid, finalScore);
    } catch (e) {
      debugPrint('❌ Admin değerlendirmesi yapılırken hata: $e');
      rethrow;
    }
  }

  /// Admin kendine atanan görevi tamamlar
  Future<void> completeTaskByAdmin(
      String taskId,
      String userCompletionNote,
      ) async {
    try {
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) {
        debugPrint('❌ Görev bulunamadı: $taskId');
        return;
      }

      final task = TaskModel.fromFirestore(taskDoc);

      await _firestore.collection('tasks').doc(taskId).update({
        'status': TaskStatus.evaluatedByAdmin.name,
        'completedAt': Timestamp.now(),
        'userCompletionNote': userCompletionNote,
        'adminScore': 100,
        'adminEvaluatedAt': Timestamp.now(),
      });

      final finalScore = 100 * task.difficultyLevel;
      await _updateUserScore(task.assignedToUid, finalScore);
    } catch (e) {
      debugPrint('❌ Admin görevi tamamlarken hata: $e');
      rethrow;
    }
  }

  // ============================================
  // CAPTAIN OPERATIONS
  // ============================================

  /// Kaptan tarafından oluşturulan görevleri getir
  Stream<List<TaskModel>> getTasksForCaptain(
      String captainUid,
      String teamId,
      ) {
    return _firestore
        .collection('tasks')
        .where('assignedByUid', isEqualTo: captainUid)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
      return _sortTasksByDate(tasks);
    });
  }

  /// Kaptanın değerlendirmesi gereken görevler
  Stream<List<TaskModel>> getTasksForCaptainEvaluation(String teamId) async* {
    try {
      final teamMembersSnapshot = await _firestore
          .collection('users')
          .where('teamId', isEqualTo: teamId)
          .get();

      final teamMemberUids = teamMembersSnapshot.docs.map((e) => e.id).toList();

      if (teamMemberUids.isEmpty) {
        yield [];
        return;
      }

      // Firestore whereIn limiti 10
      if (teamMemberUids.length > 10) {
        final List<TaskModel> allTasks = [];

        for (int i = 0; i < teamMemberUids.length; i += 10) {
          final batch = teamMemberUids.skip(i).take(10).toList();
          final snapshot = await _firestore
              .collection('tasks')
              .where('assignedToUid', whereIn: batch)
              .where('status', isEqualTo: TaskStatus.completedByUser.name)
              .get();

          allTasks.addAll(
            snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)),
          );
        }

        yield _sortTasksByDate(allTasks);
      } else {
        yield* _firestore
            .collection('tasks')
            .where('assignedToUid', whereIn: teamMemberUids)
            .where('status', isEqualTo: TaskStatus.completedByUser.name)
            .snapshots()
            .map((snapshot) {
          final tasks = snapshot.docs
              .map((doc) => TaskModel.fromFirestore(doc))
              .toList();
          return _sortTasksByDate(tasks);
        });
      }
    } catch (e) {
      debugPrint('❌ Kaptan görevleri alınırken hata: $e');
      yield [];
    }
  }

  /// Kaptan değerlendirir
  Future<void> evaluateTaskByCaptain(
      String taskId,
      String captainEvaluation,
      CaptainRating captainRating,
      ) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'status': TaskStatus.evaluatedByCaptain.name,
        'captainEvaluation': captainEvaluation,
        'captainRating': captainRating.name,
        'captainEvaluatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('❌ Kaptan değerlendirmesi yapılırken hata: $e');
      rethrow;
    }
  }

  // ============================================
  // USER OPERATIONS
  // ============================================

  /// Kullanıcının görevlerini getir (filtreli)
  Stream<List<TaskModel>> getUserTasks(
      String userId, {
        TaskStatus? status,
      }) {
    Query query = _firestore
        .collection('tasks')
        .where('assignedToUid', isEqualTo: userId);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
      return _sortTasksByDate(tasks);
    });
  }

  /// Bir kullanıcıya atanmış tüm görevleri getir
  Stream<List<TaskModel>> getTasksAssignedToUser(String userId) {
    return _firestore
        .collection('tasks')
        .where('assignedToUid', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
      return _sortTasksByDate(tasks);
    });
  }

  /// Kullanıcı görevi başlatır
  Future<void> startTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'status': TaskStatus.inProgress.name,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('❌ Görev başlatılırken hata: $e');
      rethrow;
    }
  }

  /// Kullanıcı görevi tamamlar
  Future<void> completeTask(
      String taskId,
      String userCompletionNote,
      ) async {
    try {
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) {
        debugPrint('❌ Görev bulunamadı: $taskId');
        return;
      }

      final task = TaskModel.fromFirestore(taskDoc);
      final assignedUserRole = await _getUserRole(task.assignedToUid);

      // Admin veya Kaptan ise Kaptan değerlendirmesini atla
      final newStatus = (assignedUserRole == 'admin' ||
          assignedUserRole == 'captain')
          ? TaskStatus.evaluatedByCaptain
          : TaskStatus.completedByUser;

      await _firestore.collection('tasks').doc(taskId).update({
        'status': newStatus.name,
        'completedAt': Timestamp.now(),
        'userCompletionNote': userCompletionNote,
      });
    } catch (e) {
      debugPrint('❌ Görev tamamlanırken hata: $e');
      rethrow;
    }
  }

  // ============================================
  // CRUD OPERATIONS
  // ============================================

  /// Yeni görev oluştur
  Future<void> createTask(TaskModel task) async {
    try {
      await _firestore.collection('tasks').add(task.toMap());
    } catch (e) {
      debugPrint('❌ Görev oluşturulurken hata: $e');
      rethrow;
    }
  }

  /// Görevi güncelle
  Future<void> updateTask(TaskModel task) async {
    try {
      await _firestore.collection('tasks').doc(task.id).update(task.toMap());
    } catch (e) {
      debugPrint('❌ Görev güncellenirken hata: $e');
      rethrow;
    }
  }

  /// Görevi güncelle (detaylı)
  Future<void> updateTaskWithInfo(
      String taskId,
      String title,
      String description,
      DateTime dueDate,
      String updatedByName, {
        int? difficultyLevel,
        String? assignedToUid,
        String? assignedToDisplayName,
      }) async {
    try {
      final updateData = <String, dynamic>{
        'title': title,
        'description': description,
        'dueDate': Timestamp.fromDate(dueDate),
        'updatedAt': Timestamp.now(),
        'updatedBy': updatedByName,
      };

      if (difficultyLevel != null) {
        updateData['difficultyLevel'] = difficultyLevel;
      }
      if (assignedToUid != null) {
        updateData['assignedToUid'] = assignedToUid;
      }
      if (assignedToDisplayName != null) {
        updateData['assignedToDisplayName'] = assignedToDisplayName;
      }

      await _firestore.collection('tasks').doc(taskId).update(updateData);
      await _logTaskEdit(taskId, updatedByName, title);
    } catch (e) {
      debugPrint('❌ Görev güncellenirken hata: $e');
      rethrow;
    }
  }

  /// Görevi sil
  Future<void> deleteTask(
      String taskId,
      String deletedByName,
      String taskTitle,
      ) async {
    try {
      await _logTaskDeletion(taskId, deletedByName, taskTitle);
      await _firestore.collection('tasks').doc(taskId).delete();
    } catch (e) {
      debugPrint('❌ Görev silinirken hata: $e');
      rethrow;
    }
  }

  // ============================================
  // STATISTICS & ANALYTICS
  // ============================================

  /// Görev istatistikleri
  Future<Map<String, int>> getTaskStatistics(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('assignedToUid', isEqualTo: userId)
          .get();

      int assigned = 0;
      int completed = 0;
      int evaluated = 0;

      for (final doc in snapshot.docs) {
        final task = TaskModel.fromFirestore(doc);
        if (task.status == TaskStatus.assigned) assigned++;
        if (task.status == TaskStatus.completedByUser) completed++;
        if (task.status == TaskStatus.evaluatedByAdmin) evaluated++;
      }

      return {
        'assigned': assigned,
        'completed': completed,
        'evaluated': evaluated,
        'total': snapshot.docs.length,
      };
    } catch (e) {
      debugPrint('❌ İstatistikler alınırken hata: $e');
      return {
        'assigned': 0,
        'completed': 0,
        'evaluated': 0,
        'total': 0,
      };
    }
  }

  /// Aylık performans skorlarını hesapla
  Future<Map<String, int>> calculateMonthlyScores() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final snapshot = await _firestore
          .collection('tasks')
          .where('status', isEqualTo: TaskStatus.evaluatedByAdmin.name)
          .where('adminEvaluatedAt', isGreaterThanOrEqualTo: startOfMonth)
          .where('adminEvaluatedAt', isLessThanOrEqualTo: endOfMonth)
          .get();

      final Map<String, int> monthlyScores = {};

      for (final doc in snapshot.docs) {
        final task = TaskModel.fromFirestore(doc);
        if (task.adminScore != null) {
          monthlyScores.update(
            task.assignedToUid,
                (value) => value + task.adminScore!,
            ifAbsent: () => task.adminScore!,
          );
        }
      }

      return monthlyScores;
    } catch (e) {
      debugPrint('❌ Aylık skorlar hesaplanırken hata: $e');
      return {};
    }
  }

  /// Toplam performans skorlarını hesapla
  Future<Map<String, int>> calculateTotalScores() async {
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('status', isEqualTo: TaskStatus.evaluatedByAdmin.name)
          .get();

      final Map<String, int> totalScores = {};

      for (final doc in snapshot.docs) {
        final task = TaskModel.fromFirestore(doc);
        if (task.adminScore != null) {
          totalScores.update(
            task.assignedToUid,
                (value) => value + task.adminScore!,
            ifAbsent: () => task.adminScore!,
          );
        }
      }

      return totalScores;
    } catch (e) {
      debugPrint('❌ Toplam skorlar hesaplanırken hata: $e');
      return {};
    }
  }
}