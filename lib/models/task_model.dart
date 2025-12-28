import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus {
  assigned,
  inProgress,
  completedByUser,
  evaluatedByCaptain,
  evaluatedByAdmin,
}

enum CaptainRating {
  good, // İyi
  medium, // Orta
  bad, // Kötü
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String assignedToUid;
  final String assignedToDisplayName;
  final String? assignedToTeamId;
  final String? assignedToTeamName;
  final String assignedByUid;
  final String assignedByDisplayName;
  final DateTime dueDate;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? userCompletionNote;
  final String? driveLink; // ✅ YENİ: Google Drive linki
  final String? captainEvaluation;
  final CaptainRating? captainRating;
  final DateTime? captainEvaluatedAt;
  final int? adminScore;
  final DateTime? adminEvaluatedAt;
  final DateTime? updatedAt;
  final String? updatedBy;
  final int difficultyLevel;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedToUid,
    required this.assignedToDisplayName,
    this.assignedToTeamId,
    this.assignedToTeamName,
    required this.assignedByUid,
    required this.assignedByDisplayName,
    required this.dueDate,
    this.status = TaskStatus.assigned,
    required this.createdAt,
    this.completedAt,
    this.userCompletionNote,
    this.driveLink, // ✅ YENİ
    this.captainEvaluation,
    this.captainRating,
    this.captainEvaluatedAt,
    this.adminScore,
    this.adminEvaluatedAt,
    this.updatedAt,
    this.updatedBy,
    this.difficultyLevel = 1,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      assignedToUid: data['assignedToUid'] ?? '',
      assignedToDisplayName: data['assignedToDisplayName'] ?? '',
      assignedToTeamId: data['assignedToTeamId'],
      assignedToTeamName: data['assignedToTeamName'],
      assignedByUid: data['assignedByUid'] ?? '',
      assignedByDisplayName: data['assignedByDisplayName'] ?? '',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      status: _parseTaskStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      userCompletionNote: data['userCompletionNote'],
      driveLink: data['driveLink'], // ✅ YENİ: Firestore'dan oku
      captainEvaluation: data['captainEvaluation'],
      captainRating: _parseCaptainRating(data['captainRating']),
      captainEvaluatedAt: (data['captainEvaluatedAt'] as Timestamp?)?.toDate(),
      adminScore: data['adminScore'] is int ? data['adminScore'] : (data['adminScore'] is String ? int.tryParse(data['adminScore']) : null),
      adminEvaluatedAt: (data['adminEvaluatedAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'],
      difficultyLevel: data['difficultyLevel'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'assignedToUid': assignedToUid,
      'assignedToDisplayName': assignedToDisplayName,
      'assignedToTeamId': assignedToTeamId,
      'assignedToTeamName': assignedToTeamName,
      'assignedByUid': assignedByUid,
      'assignedByDisplayName': assignedByDisplayName,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'userCompletionNote': userCompletionNote,
      'driveLink': driveLink, // ✅ YENİ: Firestore'a kaydet
      'captainEvaluation': captainEvaluation,
      'captainRating': captainRating?.name,
      'captainEvaluatedAt': captainEvaluatedAt != null ? Timestamp.fromDate(captainEvaluatedAt!) : null,
      'adminScore': adminScore,
      'adminEvaluatedAt': adminEvaluatedAt != null ? Timestamp.fromDate(adminEvaluatedAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'updatedBy': updatedBy,
      'difficultyLevel': difficultyLevel,
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? assignedToUid,
    String? assignedToDisplayName,
    String? assignedToTeamId,
    String? assignedToTeamName,
    String? assignedByUid,
    String? assignedByDisplayName,
    DateTime? dueDate,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? userCompletionNote,
    String? driveLink, // ✅ YENİ
    String? captainEvaluation,
    CaptainRating? captainRating,
    DateTime? captainEvaluatedAt,
    int? adminScore,
    DateTime? adminEvaluatedAt,
    DateTime? updatedAt,
    String? updatedBy,
    int? difficultyLevel,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedToUid: assignedToUid ?? this.assignedToUid,
      assignedToDisplayName: assignedToDisplayName ?? this.assignedToDisplayName,
      assignedToTeamId: assignedToTeamId ?? this.assignedToTeamId,
      assignedToTeamName: assignedToTeamName ?? this.assignedToTeamName,
      assignedByUid: assignedByUid ?? this.assignedByUid,
      assignedByDisplayName: assignedByDisplayName ?? this.assignedByDisplayName,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      userCompletionNote: userCompletionNote ?? this.userCompletionNote,
      driveLink: driveLink ?? this.driveLink, // ✅ YENİ
      captainEvaluation: captainEvaluation ?? this.captainEvaluation,
      captainRating: captainRating ?? this.captainRating,
      captainEvaluatedAt: captainEvaluatedAt ?? this.captainEvaluatedAt,
      adminScore: adminScore ?? this.adminScore,
      adminEvaluatedAt: adminEvaluatedAt ?? this.adminEvaluatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
    );
  }

  static TaskStatus _parseTaskStatus(dynamic status) {
    if (status is String) {
      return TaskStatus.values.firstWhere(
            (e) => e.name == status,
        orElse: () => TaskStatus.assigned,
      );
    }
    if (status is int) {
      if (status >= 0 && status < TaskStatus.values.length) {
        return TaskStatus.values[status];
      }
    }
    return TaskStatus.assigned;
  }

  static CaptainRating? _parseCaptainRating(dynamic rating) {
    if (rating is String) {
      try {
        return CaptainRating.values.firstWhere(
              (e) => e.name == rating,
        );
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}