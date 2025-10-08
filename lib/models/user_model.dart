import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final String? teamId;
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.teamId,
    required this.createdAt,
    this.lastLogin,
  });

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
      createdAt: createdAt,
      lastLogin: lastLogin,
    );
  }

  // Firestore'a veri gönderme
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'teamId': teamId,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
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
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      teamId: teamId ?? this.teamId,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
