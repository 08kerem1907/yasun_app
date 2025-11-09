import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final String? teamId;
  final String? captainId;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final int totalScore;
  final Map<String, int> monthlyScores; // {'YYYY-MM': score}

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.teamId,
    this.captainId,
    required this.createdAt,
    this.lastLogin,
    this.totalScore = 0,
    this.monthlyScores = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is UserModel && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  // Firestore'dan veri çekme
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // createdAt için güvenli dönüşüm
    DateTime createdAt;
    try {
      if (data['createdAt'] != null) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      createdAt = DateTime.now();
    }

    // lastLogin için güvenli dönüşüm
    DateTime? lastLogin;
    try {
      if (data['lastLogin'] != null) {
        lastLogin = (data['lastLogin'] as Timestamp).toDate();
      } else {
        lastLogin = null;
      }
    } catch (e) {
      lastLogin = null;
    }

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: data['role'] ?? 'user',
      teamId: data['teamId'],
      captainId: data['captainId'],
      createdAt: createdAt,
      lastLogin: lastLogin,
      totalScore: data["totalScore"] ?? 0,
      monthlyScores: Map<String, int>.from(data["monthlyScores"] ?? {}),
    );
  }

  // Firestore'a veri gönderme
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'teamId': teamId,
      'captainId': captainId,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'totalScore': totalScore,
      'monthlyScores': monthlyScores,
    };
  }

  // Rol kontrolü yardımcı metodları
  bool get isAdmin => role == 'admin';
  bool get isCaptain => role == 'captain';
  bool get isUser => role == 'user';

  // Rol görüntüleme adı
  String get roleDisplayName {
    switch (role) {
      case 'admin':
        return 'Yönetici';
      case 'captain':
        return 'Kaptan';
      case 'user':
        return 'Kullanıcı';
      default:
        return 'Bilinmeyen';
    }
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
    String? teamId,
    String? captainId,
    DateTime? createdAt,
    DateTime? lastLogin,
    int? totalScore,
    Map<String, int>? monthlyScores,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      teamId: teamId ?? this.teamId,
      captainId: captainId ?? this.captainId,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      totalScore: totalScore ?? this.totalScore,
      monthlyScores: monthlyScores ?? this.monthlyScores,
    );
  }
}

