import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/announcement_model.dart';
import '../models/user_model.dart';
import '../services/announcement_service.dart';
import '../services/user_service.dart';
import 'duyuru_detay_screen.dart'; // Detay ekranı için import

class DuyurularScreen extends StatefulWidget {
  const DuyurularScreen({super.key});

  @override
  State<DuyurularScreen> createState() => _DuyurularScreenState();
}

class _DuyurularScreenState extends State<DuyurularScreen> {
  final AnnouncementService _announcementService = AnnouncementService();
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
      final user = await _userService.getUser(firebaseUser.uid);
      if (mounted) {
        setState(() => _currentUser = user);
      }
    }
  }

  bool get _canManageAnnouncements =>
      _currentUser != null && (_currentUser!.isAdmin || _currentUser!.isCaptain);

  // Yeni duyuru oluşturma/düzenleme dialogu (Standart AlertDialog)
  Future<void> _openAnnouncementEditor({Announcement? announcement}) async {
    final titleController = TextEditingController(text: announcement?.title);
    final subtitleController = TextEditingController(text: announcement?.subtitle);
    final contentController = TextEditingController(text: announcement?.content);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(announcement == null ? 'Yeni Duyuru Oluştur' : 'Duyuruyu Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Başlık'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: subtitleController,
                  decoration: const InputDecoration(labelText: 'Alt Başlık (Özet)'),
                ),
                const SizedBox(height: 8),
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
                if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
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

                if (announcement == null) {
                  final newAnn = Announcement(
                    id: '', // Firestore tarafından atanacak
                    title: titleController.text.trim(),
                    subtitle: subtitleController.text.trim(),
                    content: contentController.text.trim(),
                    creatorUid: _currentUser!.uid,
                    creatorDisplayName: _currentUser!.displayName,
                    createdAt: DateTime.now(),
                  );
                  await _announcementService.addAnnouncement(newAnn);
                } else {
                  final updated = announcement.copyWith(
                    title: titleController.text.trim(),
                    subtitle: subtitleController.text.trim(),
                    content: contentController.text.trim(),
                    lastEditorUid: _currentUser!.uid,
                    lastEditorDisplayName: _currentUser!.displayName,
                    lastEditedAt: DateTime.now(),
                  );
                  await _announcementService.updateAnnouncement(updated);
                }

                if (mounted) Navigator.pop(context);
              },
              child: Text(announcement == null ? 'Yayınla' : 'Kaydet'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyurular'),
      ),
      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Announcement>>(
              stream: _announcementService.getAnnouncements(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Henüz duyuru bulunmamaktadır.'));
                }

                final announcements = snapshot.data!;

                return ListView.builder(
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    final announcement = announcements[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(announcement.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          announcement.subtitle.isNotEmpty
                              ? announcement.subtitle
                              : (announcement.content.length > 100
                                  ? '${announcement.content.substring(0, 100)}...'
                                  : announcement.content),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DuyuruDetayScreen(
                                announcement: announcement,
                                canManage: _canManageAnnouncements,
                                onEdit: () => _openAnnouncementEditor(announcement: announcement),
                                onDelete: () async {
                                  await _announcementService.deleteAnnouncement(announcement.id);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: _canManageAnnouncements
          ? FloatingActionButton(
              onPressed: () => _openAnnouncementEditor(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
