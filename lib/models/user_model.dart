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

  // Override: UID bazlı eşleştirme
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is UserModel && other.uid == uid;

  @override
  int get hashCode => uid.hashCode;

  // ------------------------------------------------------------
  // Firestore → UserModel
  // ------------------------------------------------------------
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? _toDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: data['role'] ?? 'user',
      teamId: data['teamId'],
      captainId: data['captainId'],
      createdAt: _toDate(data['createdAt']) ?? DateTime.now(),
      lastLogin: _toDate(data['lastLogin']),
      totalScore: data['totalScore'] ?? 0,
      monthlyScores: Map<String, int>.from(data['monthlyScores'] ?? {}),
    );
  }

  // ------------------------------------------------------------
  // UserModel → Firestore Map
  // ------------------------------------------------------------
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

  // ------------------------------------------------------------
  // ROLE HELPERS
  // ------------------------------------------------------------
  bool get isAdmin => role == 'admin';
  bool get isCaptain => role == 'captain';
  bool get isUser => role == 'user';

  String get roleDisplayName {
    switch (role) {
      case 'admin':
        return 'Yönetici';
      case 'captain':
        return 'Kaptan';
      case 'user':
        return 'Kullanıcı';
      default:
        return 'Bilinmeyen Rol';
    }
  }

  // ------------------------------------------------------------
  // COPY WITH
  // ------------------------------------------------------------
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
