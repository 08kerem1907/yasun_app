import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/announcement_model.dart';
import '../models/user_model.dart';
import '../services/announcement_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class DuyurularScreen extends StatefulWidget {
  const DuyurularScreen({super.key});

  @override
  State<DuyurularScreen> createState() => _DuyurularScreenState();
}

class _DuyurularScreenState extends State<DuyurularScreen> {
  final AnnouncementService _announcementService = AnnouncementService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      UserModel? user = await _userService.getUser(firebaseUser.uid);
      setState(() {
        _currentUser = user;
      });
    }
  }

  bool get _canManageAnnouncements =>
      _currentUser != null && (_currentUser!.isAdmin || _currentUser!.isCaptain);

  Future<void> _showAnnouncementDialog({
    Announcement? announcement,
    bool isEdit = false,
  }) async {
    final TextEditingController titleController =
        TextEditingController(text: announcement?.title ?? '');
    final TextEditingController contentController =
        TextEditingController(text: announcement?.content ?? '');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Duyuru Düzenle' : 'Yeni Duyuru Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Başlık'),
                ),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'İçerik'),
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Başlık ve içerik boş olamaz.')),
                  );
                  return;
                }

                if (_currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kullanıcı bilgisi alınamadı.')),
                  );
                  return;
                }

                if (isEdit && announcement != null) {
                  // Duyuru güncelle
                  final updatedAnnouncement = announcement.copyWith(
                    title: titleController.text,
                    content: contentController.text,
                    lastEditorUid: _currentUser!.uid,
                    lastEditorDisplayName: _currentUser!.displayName,
                    lastEditedAt: DateTime.now(),
                  );
                  await _announcementService.updateAnnouncement(updatedAnnouncement);
                } else {
                  // Yeni duyuru ekle
                  final newAnnouncement = Announcement(
                    id: '', // Firestore tarafından atanacak
                    title: titleController.text,
                    content: contentController.text,
                    creatorUid: _currentUser!.uid,
                    creatorDisplayName: _currentUser!.displayName,
                    createdAt: DateTime.now(),
                  );
                  await _announcementService.addAnnouncement(newAnnouncement);
                }
                Navigator.pop(context);
              },
              child: Text(isEdit ? 'Kaydet' : 'Ekle'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAnnouncement(String announcementId) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Duyuruyu Sil'),
          content: const Text('Bu duyuruyu silmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _announcementService.deleteAnnouncement(announcementId);
                Navigator.pop(context);
              },
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyurular'),
      ),
      body: StreamBuilder<List<Announcement>>(
        stream: _announcementService.getAnnouncements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Henüz duyuru yok.'));
          }

          final announcements = snapshot.data!;

          return ListView.builder(
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(announcement.content),
                      const SizedBox(height: 8),
                      Text(
                        'Ekleyen: ${announcement.creatorDisplayName} - ${_formatDate(announcement.createdAt)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (announcement.lastEditorDisplayName != null) ...[
                        Text(
                          'Son Düzenleyen: ${announcement.lastEditorDisplayName} - ${_formatDate(announcement.lastEditedAt!)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                      if (_canManageAnnouncements) ...[
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showAnnouncementDialog(
                                  announcement: announcement,
                                  isEdit: true,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteAnnouncement(announcement.id),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _canManageAnnouncements
          ? FloatingActionButton(
              onPressed: () => _showAnnouncementDialog(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

