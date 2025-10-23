import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Yeni görev oluştur
  Future<void> createTask(TaskModel task) async {
    await _firestore.collection('tasks').add(task.toMap());
  }

  // Bir kullanıcıya atanmış tüm görevleri getir
  Stream<List<TaskModel>> getTasksAssignedToUser(String userId) {
    return _firestore
        .collection('tasks')
        .where('assignedToUid', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TaskModel.fromFirestore(doc))
        .toList());
  }

  // Bir kaptan tarafından oluşturulan görevleri veya kaptanın ekibine atanan görevleri getir
  Stream<List<TaskModel>> getTasksForCaptain(String captainUid, String teamId) {
    return _firestore
        .collection('tasks')
        .where('assignedByUid', isEqualTo: captainUid) // Kaptanın atadığı görevler
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TaskModel.fromFirestore(doc))
        .toList());
  }

  // Bir kaptanın ekibindeki üyelere atanan ve kaptan tarafından değerlendirilmesi gereken görevleri getir
  Stream<List<TaskModel>> getTasksForCaptainEvaluation(String teamId) async* {
    // Önce ekip üyelerinin UID'lerini al
    final teamMembersSnapshot = await _firestore
        .collection('users')
        .where('teamId', isEqualTo: teamId)
        .get();

    final teamMemberUids = teamMembersSnapshot.docs.map((e) => e.id).toList();

    if (teamMemberUids.isEmpty) {
      yield []; // Ekip üyesi yoksa boş liste döndür
      return;
    }

    // Firestore'da whereIn maksimum 10 değer alabilir, bu yüzden kontrol edelim
    if (teamMemberUids.length > 10) {
      // 10'dan fazla üye varsa, sorguyu parçalara ayırmalıyız
      // Şimdilik ilk 10 üyeyi alıyoruz, daha kapsamlı bir çözüm gerekebilir
      final limitedUids = teamMemberUids.take(10).toList();

      yield* _firestore
          .collection('tasks')
          .where('assignedToUid', whereIn: limitedUids)
          .where('status', isEqualTo: TaskStatus.completedByUser.name)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList());
    } else {
      // Sonra görevleri dinle
      yield* _firestore
          .collection('tasks')
          .where('assignedToUid', whereIn: teamMemberUids)
          .where('status', isEqualTo: TaskStatus.completedByUser.name)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList());
    }
  }

  // Yönetici için tüm görevleri getir (değerlendirme bekleyen veya tamamlanmış)
  Stream<List<TaskModel>> getTasksForAdmin() {
    return _firestore
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TaskModel.fromFirestore(doc))
        .toList());
  }

  // Görevi güncelle
  Future<void> updateTask(TaskModel task) async {
    await _firestore.collection('tasks').doc(task.id).update(task.toMap());
  }

  // Görevi sil
  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
  }

  // Kullanıcının görevi tamamlaması
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

  // Kaptanın görevi değerlendirmesi
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

  // Yöneticinin görevi puanlaması
  Future<void> evaluateTaskByAdmin(
      String taskId,
      int adminScore,
      ) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': TaskStatus.evaluatedByAdmin.name,
      'adminScore': adminScore,
      'adminEvaluatedAt': Timestamp.now(),
    });
  }

  // Aylık performans skorlarını hesapla
  // Bu metod, her ayın sonunda veya talep üzerine çağrılabilir.
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