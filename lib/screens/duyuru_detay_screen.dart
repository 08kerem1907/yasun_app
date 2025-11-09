import 'package:flutter/material.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart'; // Silme işlemi için servisi kullanacağız

class DuyuruDetayScreen extends StatelessWidget {
  final Announcement announcement;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DuyuruDetayScreen({
    super.key,
    required this.announcement,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatDate(DateTime date) {
    return "${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(announcement.title),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
          if (canManage)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Silme Onayı'),
                    content: const Text('Bu duyuruyu silmek istediğinizden emin misiniz?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  onDelete();
                  if (context.mounted) Navigator.pop(context); // Detay ekranını kapat
                }
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(announcement.title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (announcement.subtitle.isNotEmpty)
                    Text(
                      announcement.subtitle,
                      style: const TextStyle(
                          fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                  const Divider(height: 20, thickness: 1),
                  Text(
                    announcement.content,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Ekleyen: ${announcement.creatorDisplayName} - ${_formatDate(announcement.createdAt)}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (announcement.lastEditorDisplayName != null)
                    Text(
                      "Son Düzenleyen: ${announcement.lastEditorDisplayName} - ${_formatDate(announcement.lastEditedAt!)}",
                      style:
                      const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
