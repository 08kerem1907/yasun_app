import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tüm kullanıcıları getir
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) {
          // Firestore'dan gelen verileri al ve sırala
          var users = snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList();
          
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
          var users = snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList();
          
          // Client-side sorting (index gerekmez)
          users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return users;
        });
  }

  // Takım üyelerini getir
  Stream<List<UserModel>> getTeamMembers(String teamId) {
    return _firestore
        .collection('users')
        .where('teamId', isEqualTo: teamId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  // Kullanıcı rolünü güncelle
  Future<void> updateUserRole(String uid, String newRole) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': newRole,
      });
    } catch (e) {
      throw 'Rol güncellenirken hata oluştu: $e';
    }
  }

  // Kullanıcı takımını güncelle
  Future<void> updateUserTeam(String uid, String? teamId) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'teamId': teamId,
      });
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
      Map<String, int> counts = {
        'admin': 0,
        'captain': 0,
        'user': 0,
      };

      for (var doc in snapshot.docs) {
        String role = doc.get('role') ?? 'user';
        counts[role] = (counts[role] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('Rol bazlı kullanıcı sayısı alınamadı: $e');
      return {'admin': 0, 'captain': 0, 'user': 0};
    }
  }

  // Kullanıcı arama
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Kullanıcı araması başarısız: $e');
      return [];
    }
  }
}
