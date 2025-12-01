import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import 'user_service.dart'; // UserService'i kullanmak için

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService(); // Kullanıcı rolünü kontrol etmek için

  // Görev atanan kullanıcının rolünü kontrol etmek için yardımcı fonksiyon
  Future<String?> _getUserRole(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data()?['role'];
    }
    return null;
  }

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

  // ✅ YENİ: Tüm değerlendirilmiş görevleri çeken fonksiyon
  Stream<List<TaskModel>> getAllEvaluatedTasks() {
    // Firestore'da tek bir sorguda iki farklı 'where' koşulu (evaluatedByAdmin VEYA evaluatedByCaptain)
    // kullanamayız. Bu nedenle, ya iki ayrı sorgu yapıp sonuçları birleştirmeliyiz ya da
    // sadece 'evaluatedByAdmin' olanları çekip, arayüzde filtreleme yapmalıyız.
    // Kullanıcının isteği "en baştan şimdiye kadar yapılan görevler ve değerlendirmeler" olduğu için,
    // en nihai değerlendirme olan 'evaluatedByAdmin' durumundaki görevleri çekmek daha mantıklıdır.
    // Kaptan değerlendirmesi tamamlanmış ancak Admin değerlendirmesi yapılmamış görevler,
    // nihai sonuç olarak kabul edilmeyebilir.
    // Ancak, gereksinime tam uymak için, her iki durumu da kapsayacak şekilde
    // 'status' alanı için 'in' sorgusu kullanmak en iyisidir.

    return _firestore
        .collection('tasks')
        .where('status', whereIn: [
      TaskStatus.evaluatedByAdmin.name,
      TaskStatus.evaluatedByCaptain.name,
    ])
        .orderBy('adminEvaluatedAt', descending: true) // En son değerlendirilenler üstte
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    });
  }
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

  Future<void> _logTaskDeletion(String taskId, String deletedByName, String taskTitle) async {
    await _firestore.collection('task_activities').add({
      'type': 'taskDeleted',
      'taskId': taskId,
      'taskTitle': taskTitle,
      'deletedBy': deletedByName,
      'timestamp': Timestamp.now(),
    });
  }
  Future<void> _logTaskEdit(String taskId, String editedByName, String taskTitle) async {
    await _firestore.collection('task_activities').add({
      'type': 'taskEdited',
      'taskId': taskId,
      'taskTitle': taskTitle,
      'editedBy': editedByName,
      'timestamp': Timestamp.now(),
    });
  }
  Future<void> createTask(TaskModel task) async {
    // TaskModel'de teamId ve teamName bilgileri zaten var (varsayarak)
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

  // ✅ DÜZELTME: Bir kullanıcıya atanmış tüm görevleri getir - DEBUG LOGGING EKLENDI
  Stream<List<TaskModel>> getTasksAssignedToUser(String userId) {
    // ✅ DEBUG: Hangi kullanıcı için görev çekildiğini logla
    print('🔍 DEBUG [TaskService]: Görevler çekiliyor - userId: $userId');

    return _firestore
        .collection('tasks')
        .where('assignedToUid', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      // ✅ DEBUG: Kaç görev bulunduğunu logla
      print('📊 DEBUG [TaskService]: Firestore\'dan ${snapshot.docs.length} görev bulundu');

      var tasks = snapshot.docs.map((doc) {
        // ✅ DEBUG: Her görevin detaylarını logla
        final data = doc.data() as Map<String, dynamic>;
        print('📝 DEBUG [TaskService]: Görev ID: ${doc.id}');
        print('   - Başlık: ${data['title']}');
        print('   - assignedToUid: ${data['assignedToUid']}');
        print('   - assignedToDisplayName: ${data['assignedToDisplayName']}');
        print('   - status: ${data['status']}');

        return TaskModel.fromFirestore(doc);
      }).toList();

      // Client-side sorting
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // ✅ DEBUG: Sıralama sonrası görev sayısını logla
      print('✅ DEBUG [TaskService]: Toplam ${tasks.length} görev döndürülüyor');

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

  // Kullanıcı görevi gördüğünü ve başladığını bildirir
  Future<void> startTask(
      String taskId,
      ) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': TaskStatus.inProgress.name,
      'updatedAt': Timestamp.now(),
      // İsteğe bağlı: 'startedAt' alanı eklenebilir
    });
  }

  // Kullanıcı görevi tamamlar
  Future<void> completeTask(
      String taskId,
      String userCompletionNote,
      ) async {
    // 1. Görevi al
    final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
    if (!taskDoc.exists) return;
    final task = TaskModel.fromFirestore(taskDoc);

    // 2. Atanan kullanıcının rolünü kontrol et
    final assignedUserRole = await _getUserRole(task.assignedToUid);

    // 3. Yeni durumu belirle
    TaskStatus newStatus;
    if (assignedUserRole == 'admin' || assignedUserRole == 'captain') {
      // Eğer görev Admin veya Kaptana atanmışsa, Kaptan değerlendirmesini atla
      newStatus = TaskStatus.evaluatedByCaptain; // Admin değerlendirmesine geçiş için
    } else {
      // Normal kullanıcı ise, Kaptan değerlendirmesine gönder
      newStatus = TaskStatus.completedByUser;
    }

    // 4. Görevi güncelle
    await _firestore.collection('tasks').doc(taskId).update({
      'status': newStatus.name,
      'completedAt': Timestamp.now(),
      'userCompletionNote': userCompletionNote,
    });
  }

  // Yönetici (Admin) kendine atanan görevi tamamlar
  Future<void> completeTaskByAdmin(
      String taskId,
      String userCompletionNote,
      ) async {
    // ✅ YENİ: Önce görevi al ki zorluk derecesine erişebilelim
    final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
    final task = TaskModel.fromFirestore(taskDoc);

    await _firestore.collection('tasks').doc(taskId).update({
      'status': TaskStatus.evaluatedByAdmin.name, // Doğrudan Admin tarafından tamamlanmış sayılır
      'completedAt': Timestamp.now(),
      'userCompletionNote': userCompletionNote,
      'adminScore': 100, // Varsayılan tam puan
      'adminEvaluatedAt': Timestamp.now(),
    });

    // ✅ YENİ: Zorluk derecesini çarpan olarak kullanıp nihai puanı hesapla
    final finalScore = 100 * task.difficultyLevel;

    // Puanı güncelleme (zorluk derecesi ile çarpılmış puan)
    await _updateUserScore(task.assignedToUid, finalScore);
  }

  // Kaptan değerlendirir
  Future<void> evaluateTaskByCaptain(
      String taskId,
      String captainEvaluation,
      CaptainRating captainRating, // ✅ YENİ: Derece eklendi
      ) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': TaskStatus.evaluatedByCaptain.name,
      'captainEvaluation': captainEvaluation,
      'captainRating': captainRating.name, // ✅ YENİ: Derece kaydedildi
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

    // ✅ YENİ: Zorluk derecesini çarpan olarak kullanıp nihai puanı hesapla
    final finalScore = adminScore * task.difficultyLevel;

    // Kullanıcının puanını güncelle (zorluk derecesi ile çarpılmış puan)
    await _updateUserScore(task.assignedToUid, finalScore);
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
  Future<void> deleteTask(String taskId, String deletedByName, String taskTitle) async {
    // Önce aktiviteyi kaydet
    await _logTaskDeletion(taskId, deletedByName, taskTitle);

    // Sonra görevi sil
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
  // TaskService sınıfına eklenecek yeni metod:

// ✅ Görevi güncelle (düzenleme bilgileriyle)
  Future<void> updateTaskWithInfo(
      String taskId,
      String title,
      String description,
      DateTime dueDate,
      String updatedByName,
      ) async {
    // Görevi güncelle
    await _firestore.collection('tasks').doc(taskId).update({
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'updatedAt': Timestamp.now(),
      'updatedBy': updatedByName,
      // Takım bilgileri bu fonksiyonla güncellenmez, sadece görev oluşturulurken atanır.
    });

    // Aktiviteyi kaydet
    await _logTaskEdit(taskId, updatedByName, title);
  }
}
