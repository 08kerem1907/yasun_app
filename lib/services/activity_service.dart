import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity_model.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';
import '../services/announcement_service.dart';

class ActivityService {
  final TaskService _taskService = TaskService();
  final UserService _userService = UserService();
  final AnnouncementService _announcementService = AnnouncementService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ActivityModel>> getRecentActivities(String currentUserId) {
    // 1. Kullanıcıya atanan görevler
    final assignedTasksStream = _taskService.getTasksAssignedToUser(currentUserId).map((tasks) {
      return tasks.map((task) {
        return ActivityModel(
          type: ActivityType.taskAssigned,
          title: 'Yeni Görev Atandı',
          subtitle: '"${task.title}" görevi size ${task.assignedByDisplayName} tarafından atandı.',
          timestamp: task.createdAt,
          icon: Icons.assignment_turned_in,
          color: Colors.blue.shade700,
        );
      }).toList();
    });

    // 2. Kullanıcının tamamladığı ve puanlanan görevler
    final evaluatedTasksStream = _taskService.getTasksAssignedToUser(currentUserId).map((tasks) {
      return tasks
          .where((task) => task.status == TaskStatus.evaluatedByAdmin && task.adminScore != null)
          .map((task) {
        return ActivityModel(
          type: ActivityType.scoreUpdated,
          title: 'Görev Puanlandı',
          subtitle: '"${task.title}" görevinizden ${task.adminScore} puan aldınız.',
          timestamp: task.adminEvaluatedAt ?? task.createdAt,
          icon: Icons.trending_up_rounded,
          color: Colors.green.shade700,
        );
      }).toList();
    });

    // 3. Yeni Duyurular
    final announcementsStream = _announcementService.getAnnouncements().map((announcements) {
      return announcements.map((announcement) {
        return ActivityModel(
          type: ActivityType.announcementPublished,
          title: 'Yeni Duyuru: ${announcement.title}',
          subtitle: announcement.subtitle.isNotEmpty ? announcement.subtitle : announcement.content,
          timestamp: announcement.createdAt,
          icon: Icons.campaign,
          color: Colors.orange.shade700,
        );
      }).toList();
    });

    // 4. Yeni Kullanıcılar
    final newUsersStream = _userService.getAllUsers().map((users) {
      return users.take(5).map((user) {
        return ActivityModel(
          type: ActivityType.userJoined,
          title: 'Yeni Üye Katıldı',
          subtitle: '${user.displayName} (${user.roleDisplayName}) ekibe katıldı.',
          timestamp: user.createdAt,
          icon: Icons.person_add_alt_1_rounded,
          color: Colors.purple.shade700,
        );
      }).toList();
    });

    // ✅ 5. Görev Silme Aktiviteleri
    final taskDeletionsStream = _firestore
        .collection('task_activities')
        .where('type', isEqualTo: 'taskDeleted')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ActivityModel(
          type: ActivityType.taskDeleted,
          title: 'Görev Silindi',
          subtitle: '${data['deletedBy']} tarafından "${data['taskTitle']}" görevi silindi.',
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          icon: Icons.delete_forever,
          color: Colors.red.shade700,
        );
      }).toList();
    });

    // ✅ 6. Görev Düzenleme Aktiviteleri
    final taskEditsStream = _firestore
        .collection('task_activities')
        .where('type', isEqualTo: 'taskEdited')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ActivityModel(
          type: ActivityType.taskEdited,
          title: 'Görev Düzenlendi',
          subtitle: '${data['editedBy']} tarafından "${data['taskTitle']}" görevi düzenlendi.',
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          icon: Icons.edit_note,
          color: Colors.indigo.shade700,
        );
      }).toList();
    });

    // Tüm akışları birleştir
    return Rx.combineLatest6(
      assignedTasksStream,
      evaluatedTasksStream,
      announcementsStream,
      newUsersStream,
      taskDeletionsStream,
      taskEditsStream,
          (
          List<ActivityModel> assigned,
          List<ActivityModel> evaluated,
          List<ActivityModel> announcements,
          List<ActivityModel> newUsers,
          List<ActivityModel> deletions,
          List<ActivityModel> edits,
          ) {
        final allActivities = [
          ...assigned,
          ...evaluated,
          ...announcements,
          ...newUsers,
          ...deletions,
          ...edits,
        ];
        allActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return allActivities.take(10).toList();
      },
    );
  }
}