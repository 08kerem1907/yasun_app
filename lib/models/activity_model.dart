import 'package:flutter/material.dart';

enum ActivityType {
  taskAssigned,
  taskCompleted,
  taskEvaluated,
  scoreUpdated,
  userJoined,
  announcementPublished,
  taskDeleted,
  taskEdited,
  userDeleted,  // ✅ YENİ: Kullanıcı silme
}

class ActivityModel {
  final ActivityType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final IconData icon;
  final Color color;
  final String? performedByUid;
  final String? performedByName;
  final String? deletedUserUid;
  final String? deletedUserName;
  final String? deletedUserEmail;
  final String? deletedUserRole;

  ActivityModel({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    required this.color,
    this.performedByUid,
    this.performedByName,
    this.deletedUserUid,
    this.deletedUserName,
    this.deletedUserEmail,
    this.deletedUserRole,
  });

  // Firestore'dan veri çekme
  factory ActivityModel.fromFirestore(Map<String, dynamic> data) {
    ActivityType type = ActivityType.userJoined;

    switch (data['type']) {
      case 'taskAssigned':
        type = ActivityType.taskAssigned;
        break;
      case 'taskCompleted':
        type = ActivityType.taskCompleted;
        break;
      case 'taskEvaluated':
        type = ActivityType.taskEvaluated;
        break;
      case 'scoreUpdated':
        type = ActivityType.scoreUpdated;
        break;
      case 'userJoined':
        type = ActivityType.userJoined;
        break;
      case 'announcementPublished':
        type = ActivityType.announcementPublished;
        break;
      case 'taskDeleted':
        type = ActivityType.taskDeleted;
        break;
      case 'taskEdited':
        type = ActivityType.taskEdited;
        break;
      case 'userDeleted':
        type = ActivityType.userDeleted;
        break;
    }

    return ActivityModel(
      type: type,
      title: data['title'] ?? 'Aktivite',
      subtitle: data['subtitle'] ?? '',
      timestamp: (data['timestamp'] as dynamic).toDate() ?? DateTime.now(),
      icon: _getIconForType(type),
      color: _getColorForType(type),
      performedByUid: data['performedByUid'],
      performedByName: data['performedByName'],
      deletedUserUid: data['deletedUserUid'],
      deletedUserName: data['deletedUserName'],
      deletedUserEmail: data['deletedUserEmail'],
      deletedUserRole: data['deletedUserRole'],
    );
  }

  static IconData _getIconForType(ActivityType type) {
    switch (type) {
      case ActivityType.taskAssigned:
        return Icons.assignment;
      case ActivityType.taskCompleted:
        return Icons.check_circle;
      case ActivityType.taskEvaluated:
        return Icons.rate_review;
      case ActivityType.scoreUpdated:
        return Icons.emoji_events;
      case ActivityType.userJoined:
        return Icons.person_add;
      case ActivityType.announcementPublished:
        return Icons.notifications;
      case ActivityType.taskDeleted:
        return Icons.delete_outline;
      case ActivityType.taskEdited:
        return Icons.edit;
      case ActivityType.userDeleted:
        return Icons.person_remove;
    }
  }

  static Color _getColorForType(ActivityType type) {
    switch (type) {
      case ActivityType.taskAssigned:
        return Colors.blue;
      case ActivityType.taskCompleted:
        return Colors.green;
      case ActivityType.taskEvaluated:
        return Colors.orange;
      case ActivityType.scoreUpdated:
        return Colors.amber;
      case ActivityType.userJoined:
        return Colors.cyan;
      case ActivityType.announcementPublished:
        return Colors.purple;
      case ActivityType.taskDeleted:
        return Colors.red;
      case ActivityType.taskEdited:
        return Colors.indigo;
      case ActivityType.userDeleted:
        return Colors.redAccent;
    }
  }
}