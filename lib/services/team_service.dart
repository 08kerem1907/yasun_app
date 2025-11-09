import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';
import 'user_service.dart';

class TeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  // Yeni takım oluşturma
  Future<void> createTeam({
    required String teamName,
    required UserModel captain,
    required List<UserModel> members,
  }) async {
    // 1. Takım dokümanını oluştur
    final teamRef = _firestore.collection('teams').doc();
    final teamId = teamRef.id;
    final teamModel = TeamModel(
      id: teamId,
      name: teamName,
      captainId: captain.uid,
      memberIds: [captain.uid, ...members.map((m) => m.uid)],
      createdAt: DateTime.now(),
    );

    await teamRef.set(teamModel.toMap());

    // 2. Kaptanın rolünü ve takım bilgilerini güncelle
    await _userService.updateUserRole(captain.uid, 'captain');
    await _userService.updateUserTeam(captain.uid, teamId);
    await _userService.updateUserCaptain(captain.uid, null); // Kaptanın kendi kaptanı olmaz

    // 3. Üyelerin rolünü ve takım bilgilerini güncelle
    for (var member in members) {
      await _userService.updateUserRole(member.uid, 'user'); // Üye rolünü koru veya user yap
      await _userService.updateUserTeam(member.uid, teamId);
      await _userService.updateUserCaptain(member.uid, captain.uid);
    }
  }

  // Tüm takımları getir
  Stream<List<TeamModel>> getAllTeams() {
    return _firestore.collection('teams').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TeamModel.fromFirestore(doc)).toList();
    });
  }

  // Takım bilgilerini getir
  Future<TeamModel?> getTeam(String teamId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('teams').doc(teamId).get();
      if (doc.exists) {
        return TeamModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Takım bilgileri alınamadı: $e');
      return null;
    }
  }

  // Takımı silme (İleride eklenebilir)
  // Future<void> deleteTeam(String teamId) async { ... }
}
