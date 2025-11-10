import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import 'user_service.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  // ... diğer metodlar aynı kalacak ...

  // ✅ INDEX GEREKTİRMEYEN VERSİYON
  // Admin için değerlendirme bekleyen görevler - İki farklı yaklaşım

  // YAKLAŞIM 1: Sadece status'e göre filtrele, client-side sorting
  Stream<List<TaskModel>> getTasksForAdminEvaluation() {
    return _firestore
        .collection('tasks')
        .where('status', isEqualTo: TaskStatus.evaluatedByCaptain.name)
    // orderBy kaldırıldı - index gereksinimini ortadan kaldırır
        .snapshots()
        .map((snapshot) {
      var tasks = snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();

      // Client-side sorting (Flutter tarafında sıralama)
      tasks.sort((a, b) {
        if (a.captainEvaluatedAt == null && b.captainEvaluatedAt == null) return 0;
        if (a.captainEvaluatedAt == null) return 1;
        if (b.captainEvaluatedAt == null) return -1;
        return b.captainEvaluatedAt!.compareTo(a.captainEvaluatedAt!);
      });

      return tasks;
    });
  }

  // YAKLAŞIM 2: Limit kullanarak
  Stream<List<TaskModel>> getTasksForAdminEvaluationLimited({int limit = 50}) {
    return _firestore
        .collection('tasks')
        .where('status', isEqualTo: TaskStatus.evaluatedByCaptain.name)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      var tasks = snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();

      // Client-side sorting
      tasks.sort((a, b) {
        if (a.captainEvaluatedAt == null && b.captainEvaluatedAt == null) return 0;
        if (a.captainEvaluatedAt == null) return 1;
        if (b.captainEvaluatedAt == null) return -1;
        return b.captainEvaluatedAt!.compareTo(a.captainEvaluatedAt!);
      });

      return tasks;
    });
  }

  // YAKLAŞIM 3: Tüm görevleri al, Flutter'da filtrele (küçük veritabanları için)
  Stream<List<TaskModel>> getTasksForAdminEvaluationManual() {
    return _firestore
        .collection('tasks')
        .snapshots()
        .map((snapshot) {
      var tasks = snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .where((task) => task.status == TaskStatus.evaluatedByCaptain)
          .toList();

      // Sıralama
      tasks.sort((a, b) {
        if (a.captainEvaluatedAt == null && b.captainEvaluatedAt == null) return 0;
        if (a.captainEvaluatedAt == null) return 1;
        if (b.captainEvaluatedAt == null) return -1;
        return b.captainEvaluatedAt!.compareTo(a.captainEvaluatedAt!);
      });

      return tasks;
    });
  }

  // Yeni görev oluştur
  Future<void> createTask(TaskModel task) async {
    await _firestore.collection('tasks').add(task.toMap());
  }

  // Kullanıcının görevlerini getir (filtreli)
  Stream<List<TaskModel>> getUserTasks(String userId, {TaskStatus? status}) {
    Query query = _firestore
        .collection('tasks')
        .where('assignedToUid', isEqualTo: userId);

    // orderBy kaldırıldı
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map((snapshot) {
      var tasks = snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();

      // Client-side sorting
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return tasks;
    });
  }

  // Bir kullanıcıya atanmış tüm görevleri getir
  Stream<List<TaskModel>> getTasksAssignedToUser(String userId) {
    return _firestore
        .collection('tasks')
        .where('assignedToUid', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      var tasks = snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();

      // Client-side sorting
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return tasks;
    });
  }

  // Bir kaptan tarafından oluşturulan görevleri getir
  Stream<List<TaskModel>> getTasksForCaptain(String captainUid, String teamId) {
    return _firestore
        .collection('tasks')
        .where('assignedByUid', isEqualTo: captainUid)
        .snapshots()
        .map((snapshot) {
      var tasks = snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();

      // Client-side sorting
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return tasks;
    });
  }

  // Kullanıcı görevi tamamlar
  Future<void> completeTask(
      String taskId,
      String userCompletionNote,
      ) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': TaskStatus.completedByUser.name,
      'completedAt': Timestamp.now(),
      'userCompletionNote': userCompletionNote,
    });
  }

  // Yönetici (Admin) kendine atanan görevi tamamlar
  Future<void> completeTaskByAdmin(
      String taskId,
      String userCompletionNote,
      ) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': TaskStatus.evaluatedByAdmin.name, // Doğrudan Admin tarafından tamamlanmış sayılır
      'completedAt': Timestamp.now(),
      'userCompletionNote': userCompletionNote,
      'adminScore': 100, // Varsayılan tam puan
      'adminEvaluatedAt': Timestamp.now(),
    });

    // Puanı güncelleme
    final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
    final task = TaskModel.fromFirestore(taskDoc);
    await _updateUserScore(task.assignedToUid, 100);
  }

  // Kaptan değerlendirir
  Future<void> evaluateTaskByCaptain(
      String taskId,
      String captainEvaluation,
      ) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': TaskStatus.evaluatedByCaptain.name,
      'captainEvaluation': captainEvaluation,
      'captainEvaluatedAt': Timestamp.now(),
    });
  }

  // Admin puanlar ve kullanıcının puanını günceller
  Future<void> evaluateTaskByAdmin(
      String taskId,
      int adminScore,
      ) async {
    // Görevi güncelle
    final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
    final task = TaskModel.fromFirestore(taskDoc);

    await _firestore.collection('tasks').doc(taskId).update({
      'status': TaskStatus.evaluatedByAdmin.name,
      'adminScore': adminScore,
      'adminEvaluatedAt': Timestamp.now(),
    });

    // Kullanıcının puanını güncelle
    await _updateUserScore(task.assignedToUid, adminScore);
  }

  // Kullanıcı puanını güncelle (aylık ve toplam)
  Future<void> _updateUserScore(String userId, int scoreToAdd) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final user = UserModel.fromFirestore(userDoc);

    // Aylık puan anahtarı
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // Yeni puanları hesapla
    final newTotalScore = user.totalScore + scoreToAdd;
    final currentMonthlyScore = user.monthlyScores[monthKey] ?? 0;
    final newMonthlyScore = currentMonthlyScore + scoreToAdd;

    // Güncelle
    final updatedMonthlyScores = Map<String, int>.from(user.monthlyScores);
    updatedMonthlyScores[monthKey] = newMonthlyScore;

    await _firestore.collection('users').doc(userId).update({
      'totalScore': newTotalScore,
      'monthlyScores': updatedMonthlyScores,
    });
  }

  // Kaptanın değerlendirmesi gereken görevler
  Stream<List<TaskModel>> getTasksForCaptainEvaluation(String teamId) async* {
    // Takım üyelerini al
    final teamMembersSnapshot = await _firestore
        .collection('users')
        .where('teamId', isEqualTo: teamId)
        .get();

    final teamMemberUids = teamMembersSnapshot.docs.map((e) => e.id).toList();

    if (teamMemberUids.isEmpty) {
      yield [];
      return;
    }

    // Firestore'da whereIn limiti 10
    if (teamMemberUids.length > 10) {
      // Birden fazla sorgu gerekiyor
      final List<TaskModel> allTasks = [];

      for (int i = 0; i < teamMemberUids.length; i += 10) {
        final batch = teamMemberUids.skip(i).take(10).toList();
        final snapshot = await _firestore
            .collection('tasks')
            .where('assignedToUid', whereIn: batch)
            .where('status', isEqualTo: TaskStatus.completedByUser.name)
            .get();

        allTasks.addAll(
            snapshot.docs.map((doc) => TaskModel.fromFirestore(doc))
        );
      }

      // Client-side sorting
      allTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      yield allTasks;
    } else {
      yield* _firestore
          .collection('tasks')
          .where('assignedToUid', whereIn: teamMemberUids)
          .where('status', isEqualTo: TaskStatus.completedByUser.name)
          .snapshots()
          .map((snapshot) {
        var tasks = snapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList();

        // Client-side sorting
        tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return tasks;
      });
    }
  }

  // Admin için tüm görevleri getir
  Stream<List<TaskModel>> getTasksForAdmin() {
    return _firestore
        .collection('tasks')
        .snapshots()
        .map((snapshot) {
      var tasks = snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();

      // Client-side sorting
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return tasks;
    });
  }

  // Görev istatistikleri
  Future<Map<String, int>> getTaskStatistics(String userId) async {
    final snapshot = await _firestore
        .collection('tasks')
        .where('assignedToUid', isEqualTo: userId)
        .get();

    int assigned = 0;
    int completed = 0;
    int evaluated = 0;

    for (var doc in snapshot.docs) {
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
  }

  // Görevi sil
  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
  }

  // Görevi güncelle
  Future<void> updateTask(TaskModel task) async {
    await _firestore.collection('tasks').doc(task.id).update(task.toMap());
  }

  // Aylık performans skorlarını hesapla
  Future<Map<String, int>> calculateMonthlyScores() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final QuerySnapshot completedTasksSnapshot = await _firestore
        .collection('tasks')
        .where('status', isEqualTo: TaskStatus.evaluatedByAdmin.name)
        .where('adminEvaluatedAt', isGreaterThanOrEqualTo: startOfMonth)
        .where('adminEvaluatedAt', isLessThanOrEqualTo: endOfMonth)
        .get();

    Map<String, int> monthlyScores = {};

    for (var doc in completedTasksSnapshot.docs) {
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
  }

  // Toplam performans skorlarını hesapla
  Future<Map<String, int>> calculateTotalScores() async {
    final QuerySnapshot completedTasksSnapshot = await _firestore
        .collection('tasks')
        .where('status', isEqualTo: TaskStatus.evaluatedByAdmin.name)
        .get();

    Map<String, int> totalScores = {};

    for (var doc in completedTasksSnapshot.docs) {
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
  }
}