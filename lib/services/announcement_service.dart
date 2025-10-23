import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/announcement_model.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Duyuru ekle
  Future<void> addAnnouncement(Announcement announcement) async {
    await _firestore.collection('announcements').add(announcement.toMap());
  }

  // Tüm duyuruları getir (tarihe göre sıralanmış)
  Stream<List<Announcement>> getAnnouncements() {
    return _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Announcement.fromFirestore(doc)).toList();
    });
  }

  // Duyuru güncelle
  Future<void> updateAnnouncement(Announcement announcement) async {
    await _firestore.collection('announcements').doc(announcement.id).update(announcement.toMap());
  }

  // Duyuru sil
  Future<void> deleteAnnouncement(String announcementId) async {
    await _firestore.collection('announcements').doc(announcementId).delete();
  }
}

