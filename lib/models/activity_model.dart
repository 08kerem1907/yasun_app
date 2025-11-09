import 'package:flutter/material.dart';

enum ActivityType {
  taskAssigned,
  taskCompleted,
  taskEvaluated,
  scoreUpdated, // Görev puanlaması veya manuel puan güncellemesi
  // Puan yükselmesi için ayrı bir tip eklemeye gerek yok, scoreUpdated yeterli.
  // Ancak, puanın yükseldiğini daha spesifik belirtmek için gerekirse eklenebilir.
  // Mevcut yapıda scoreUpdated'ı kullanmak daha mantıklı.
  // Eğer scoreUpdated sadece görev puanlaması için kullanılıyorsa, yeni bir tip ekleyelim.
  // Mevcut kodda scoreUpdated hem görev puanlaması hem de manuel puan güncellemesi için kullanılıyor.
  // Bu nedenle, yeni bir tip eklemeye gerek yok, sadece ActivityService'i güncelleyeceğiz.
  userJoined,
  announcementPublished,
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
