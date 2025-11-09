import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus {
  assigned,
  completedByUser,
  evaluatedByCaptain,
  evaluatedByAdmin,
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String assignedToUid;
  final String assignedToDisplayName;
  final String assignedByUid;
  final String assignedByDisplayName;
  final DateTime dueDate;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? userCompletionNote;
  final String? captainEvaluation;
  final DateTime? captainEvaluatedAt;
  final int? adminScore;
  final DateTime? adminEvaluatedAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedToUid,
    required this.assignedToDisplayName,
    required this.assignedByUid,
    required this.assignedByDisplayName,
    required this.dueDate,
    this.status = TaskStatus.assigned,
    required this.createdAt,
    this.completedAt,
    this.userCompletionNote,
    this.captainEvaluation,
    this.captainEvaluatedAt,
    this.adminScore,
    this.adminEvaluatedAt,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      assignedToUid: data['assignedToUid'] ?? '',
      assignedToDisplayName: data['assignedToDisplayName'] ?? '',
      assignedByUid: data['assignedByUid'] ?? '',
      assignedByDisplayName: data['assignedByDisplayName'] ?? '',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      status: _parseTaskStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      userCompletionNote: data['userCompletionNote'],
      captainEvaluation: data['captainEvaluation'],
      captainEvaluatedAt: (data['captainEvaluatedAt'] as Timestamp?)?.toDate(),
      adminScore: data['adminScore'] is int ? data['adminScore'] : (data['adminScore'] is String ? int.tryParse(data['adminScore']) : null),
      adminEvaluatedAt: (data['adminEvaluatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'assignedToUid': assignedToUid,
      'assignedToDisplayName': assignedToDisplayName,
      'assignedByUid': assignedByUid,
      'assignedByDisplayName': assignedByDisplayName,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'userCompletionNote': userCompletionNote,
      'captainEvaluation': captainEvaluation,
      'captainEvaluatedAt': captainEvaluatedAt != null ? Timestamp.fromDate(captainEvaluatedAt!) : null,
      'adminScore': adminScore,
      'adminEvaluatedAt': adminEvaluatedAt != null ? Timestamp.fromDate(adminEvaluatedAt!) : null,
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? assignedToUid,
    String? assignedToDisplayName,
    String? assignedByUid,
    String? assignedByDisplayName,
    DateTime? dueDate,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? userCompletionNote,
    String? captainEvaluation,
    DateTime? captainEvaluatedAt,
    int? adminScore,
    DateTime? adminEvaluatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedToUid: assignedToUid ?? this.assignedToUid,
      assignedToDisplayName: assignedToDisplayName ?? this.assignedToDisplayName,
      assignedByUid: assignedByUid ?? this.assignedByUid,
      assignedByDisplayName: assignedByDisplayName ?? this.assignedByDisplayName,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      userCompletionNote: userCompletionNote ?? this.userCompletionNote,
      captainEvaluation: captainEvaluation ?? this.captainEvaluation,
      captainEvaluatedAt: captainEvaluatedAt ?? this.captainEvaluatedAt,
      adminScore: adminScore ?? this.adminScore,
      adminEvaluatedAt: adminEvaluatedAt ?? this.adminEvaluatedAt,
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
}

