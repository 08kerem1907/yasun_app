import 'package:flutter/material.dart';

enum ActivityType {
  taskAssigned,
  taskCompleted,
  taskEvaluated,
  scoreUpdated,
  userJoined,
  announcementPublished,
  taskDeleted,      // ✅ YENİ: Görev silme
  taskEdited,       // ✅ YENİ: Görev düzenleme
}

class ActivityModel {
  final ActivityType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final IconData icon;
  final Color color;

  ActivityModel({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    required this.color,
  });
}