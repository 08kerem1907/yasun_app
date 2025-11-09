import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../models/activity_model.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';
import '../services/announcement_service.dart';

class ActivityService {
  final TaskService _taskService = TaskService();
  final UserService _userService = UserService();
  final AnnouncementService _announcementService = AnnouncementService();

  // Tüm aktivite akışlarını birleştirip sıralayan ana Stream
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

    // 2. Kullanıcının tamamladığı ve puanlanan görevler (Puan Güncellemesi olarak ele alalım)
    // Bu, daha karmaşık bir mantık gerektirir. Şimdilik sadece admin tarafından puanlanan görevleri alalım.
    // Ancak TaskService'de tüm görevleri çeken bir metod yok. Bu yüzden, kullanıcının atandığı görevler üzerinden filtreleme yapalım.
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

    // 4. Yeni Kullanıcılar (Sadece son 10 kullanıcıyı çekiyoruz, gerçek zamanlı akış zor)
    // UserService'de getAllUsers Stream'i var, onu kullanabiliriz.
    final newUsersStream = _userService.getAllUsers().map((users) {
      // Kullanıcıları createdAt'e göre sırala (getAllUsers zaten sıralıyor)
      return users.take(5).map((user) { // Son 5 kullanıcıyı al
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

    // 5. Puan Yükselişleri (Tüm kullanıcıların puanlarını izle)
    // Bu, tüm kullanıcıların verilerini sürekli dinleyecektir.
    // Gerçek bir puan yükselişi aktivitesi için, puanın ne zaman yükseldiğini bilmemiz gerekir.
    // UserModel'de puanın en son ne zaman güncellendiğini gösteren bir alan yok.
    // Bu nedenle, sadece görev puanlamalarını (evaluatedTasksStream) ve yeni kullanıcıları (userJoined)
    // puan yükselişi olarak kabul edeceğiz.
    // Ancak, kullanıcı isteği üzerine, tüm kullanıcıların toplam puanlarını çekip,
    // puanı en son güncellenen (createdAt'i en yakın olan) kullanıcıları aktivite olarak ekleyebiliriz.
    // Bu, bir "puan güncellemesi" aktivitesi yaratmanın en iyi yolu değildir, ancak mevcut veri yapınızla mümkün olan en yakın çözümdür.

    // Puan yükselişi aktivitesi için, evaluatedTasksStream'i kullanmak en doğru yoldur.
    // Kullanıcı isteği, "puanı yükselende gözüksün" olduğu için, evaluatedTasksStream'i kullanmaya devam edeceğiz.
    // Eğer kullanıcı manuel puan eklemesi yapıyorsa, bu da evaluatedTasksStream'e düşecektir.

    // Tüm akışları birleştir ve zaman damgasına göre sırala
    return Rx.combineLatest4(
      assignedTasksStream,
      evaluatedTasksStream,
      announcementsStream,
      newUsersStream,
          (List<ActivityModel> assigned, List<ActivityModel> evaluated, List<ActivityModel> announcements, List<ActivityModel> newUsers) {
        final allActivities = [...assigned, ...evaluated, ...announcements, ...newUsers];
        allActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return allActivities.take(10).toList(); // Son 10 aktiviteyi al
      },
    );
  }
}
