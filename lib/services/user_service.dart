import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tüm kullanıcıları getir
  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      // Firestore'dan gelen verileri al ve sırala
      var users =
      snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

      // Client-side sorting (index gerekmez)
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return users;
    });
  }

  // Belirli bir role sahip kullanıcıları getir
  Stream<List<UserModel>> getUsersByRole(String role) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snapshot) {
      // Firestore'dan gelen verileri al ve sırala
      var users =
      snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

      // Client-side sorting (index gerekmez)
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return users;
    });
  }

  // Kaptana bağlı üyeleri getir
  Stream<List<UserModel>> getTeamMembers(String captainId) {
    return _firestore
        .collection('users')
        .where('captainId', isEqualTo: captainId)
        .snapshots()
        .map((snapshot) {
      // Client-side sorting ile sıralama yapıyoruz
      var users = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return users;
    });
  }

  // Kullanıcı rolünü güncelle
  Future<void> updateUserRole(String uid, String newRole) async {
    try {
      await _firestore.collection('users').doc(uid).update({'role': newRole});
    } catch (e) {
      throw 'Rol güncellenirken hata oluştu: $e';
    }
  }

  // Kullanıcı kaptanını güncelle
  Future<void> updateUserCaptain(String uid, String? captainId) async {
    try {
      await _firestore.collection('users').doc(uid).update({'captainId': captainId});
    } catch (e) {
      throw 'Kaptan güncellenirken hata oluştu: $e';
    }
  }

  // Kullanıcının takımını güncelle
  Future<void> updateUserTeam(String uid, String? teamId) async {
    try {
      await _firestore.collection('users').doc(uid).update({'teamId': teamId});
    } catch (e) {
      throw 'Takım güncellenirken hata oluştu: $e';
    }
  }

  // Kullanıcı görünen adını güncelle
  Future<void> updateUserDisplayName(String uid, String displayName) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'displayName': displayName,
      });
    } catch (e) {
      throw 'İsim güncellenirken hata oluştu: $e';
    }
  }

  // Kullanıcıyı sil
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      throw 'Kullanıcı silinirken hata oluştu: $e';
    }
  }

  // Kullanıcı sayısını getir
  Future<int> getUserCount() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      return snapshot.docs.length;
    } catch (e) {
      print('Kullanıcı sayısı alınamadı: $e');
      return 0;
    }
  }

  // Role göre kullanıcı sayısını getir
  Future<Map<String, int>> getUserCountByRole() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      Map<String, int> counts = {'admin': 0, 'captain': 0, 'user': 0};

      for (var doc in snapshot.docs) {
        try {
          // UserModel kullanarak rol bilgisini al
          UserModel user = UserModel.fromFirestore(doc);
          String role = user.role;

          // Rolü say
          if (counts.containsKey(role)) {
            counts[role] = (counts[role] ?? 0) + 1;
          } else {
            // Bilinmeyen rol varsa user olarak say
            counts['user'] = (counts['user'] ?? 0) + 1;
          }

          // Debug için
          print('Kullanıcı: ${user.displayName}, Rol: $role');
        } catch (e) {
          print('Kullanıcı verisi işlenirken hata: $e');
        }
      }

      print('Rol Sayıları: $counts');
      return counts;
    } catch (e) {
      print('Rol bazlı kullanıcı sayısı alınamadı: $e');
      return {'admin': 0, 'captain': 0, 'user': 0};
    }
  }

  // Kullanıcı arama
  Future<int> getActiveTaskCount(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('assignedToUid', isEqualTo: uid)
          .where('status', isEqualTo: 'assigned') // Atanmış görevler
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Aktif görev sayısı alınamadı: $e');
      return 0;
    }
  }

  Future<int> getCompletedTaskCount(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('assignedToUid', isEqualTo: uid)
          .where('status', isEqualTo: 'evaluatedByAdmin') // Yönetici tarafından puanlanmış görevler
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Tamamlanmış görev sayısı alınamadı: $e');
      return 0;
    }
  }

  // Kullanıcının puanlarını güncelle
  Future<void> updateUserScores(String uid, int totalScore, Map<String, int> monthlyScores) async {
    try {
      await _firestore.collection("users").doc(uid).update({
        "totalScore": totalScore,
        "monthlyScores": monthlyScores,
      });
    } catch (e) {
      print("Kullanıcı puanları güncellenirken hata oluştu: $e");
      rethrow;
    }
  }

  Future<int> getTotalScore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final user = UserModel.fromFirestore(doc);
        return user.totalScore;
      }
      return 0;
    } catch (e) {
      print('Toplam puan alınamadı: $e');
      return 0;
    }
  }

  Future<int> getTeamMemberCount(String captainUid) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('captainId', isEqualTo: captainUid)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Takım üye sayısı alınamadı: $e');
      return 0;
    }
  }

  Future<int> getCompletedTasksThisMonth(String captainUid) async {
    try {
      // 1. Kaptanın takım üyelerini bul
      final teamMembersSnapshot = await _firestore
          .collection('users')
          .where('captainId', isEqualTo: captainUid)
          .get();

      final teamMemberUids = teamMembersSnapshot.docs.map((e) => e.id).toList();

      if (teamMemberUids.isEmpty) {
        return 0;
      }

      // 2. Bu ayın başlangıç ve bitiş tarihlerini bul
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      int completedCount = 0;

      // Firestore whereIn limiti 10 olduğu için parçalara ayır
      for (int i = 0; i < teamMemberUids.length; i += 10) {
        final batch = teamMemberUids.skip(i).take(10).toList();

        final snapshot = await _firestore
            .collection('tasks')
            .where('assignedToUid', whereIn: batch)
            .where('status', isEqualTo: 'evaluatedByAdmin')
            .where('adminEvaluatedAt', isGreaterThanOrEqualTo: startOfMonth)
            .where('adminEvaluatedAt', isLessThanOrEqualTo: endOfMonth)
            .get();

        completedCount += snapshot.docs.length;
      }

      return completedCount;
    } catch (e) {
      print('Bu ay tamamlanan görev sayısı alınamadı: $e');
      return 0;
    }
  }

  Future<int> getSystemScore() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      int totalScore = 0;
      for (var doc in snapshot.docs) {
        final user = UserModel.fromFirestore(doc);
        totalScore += user.totalScore;
      }
      return totalScore;
    } catch (e) {
      print('Sistem puanı alınamadı: $e');
      return 0;
    }
  }

  // Kullanıcı arama
  // Belirli bir kullanıcıyı UID ile getir
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection("users").doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      } else {
        return null;
      }
    } catch (e) {
      print("Kullanıcı getirilirken hata oluştu: $e");
      return null;
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      QuerySnapshot snapshot =
      await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Kullanıcı araması başarısız: $e');
      return [];
    }
  }
}