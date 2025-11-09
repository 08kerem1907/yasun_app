import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String id;
  final String name;
  final String captainId;
  final List<String> memberIds;
  final DateTime createdAt;

  TeamModel({
    required this.id,
    required this.name,
    required this.captainId,
    required this.memberIds,
    required this.createdAt,
  });

  factory TeamModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TeamModel(
      id: doc.id,
      name: data['name'] ?? '',
      captainId: data['captainId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'captainId': captainId,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  TeamModel copyWith({
    String? id,
    String? name,
    String? captainId,
    List<String>? memberIds,
    DateTime? createdAt,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      captainId: captainId ?? this.captainId,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
