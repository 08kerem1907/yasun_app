import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final String creatorUid;
  final String creatorDisplayName;
  final DateTime createdAt;
  final String? lastEditorUid;
  final String? lastEditorDisplayName;
  final DateTime? lastEditedAt;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.creatorUid,
    required this.creatorDisplayName,
    required this.createdAt,
    this.lastEditorUid,
    this.lastEditorDisplayName,
    this.lastEditedAt,
  });

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Announcement(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      creatorUid: data['creatorUid'] ?? '',
      creatorDisplayName: data['creatorDisplayName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastEditorUid: data['lastEditorUid'],
      lastEditorDisplayName: data['lastEditorDisplayName'],
      lastEditedAt: (data['lastEditedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'creatorUid': creatorUid,
      'creatorDisplayName': creatorDisplayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastEditorUid': lastEditorUid,
      'lastEditorDisplayName': lastEditorDisplayName,
      'lastEditedAt': lastEditedAt != null ? Timestamp.fromDate(lastEditedAt!) : null,
    };
  }

  Announcement copyWith({
    String? id,
    String? title,
    String? content,
    String? creatorUid,
    String? creatorDisplayName,
    DateTime? createdAt,
    String? lastEditorUid,
    String? lastEditorDisplayName,
    DateTime? lastEditedAt,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      creatorUid: creatorUid ?? this.creatorUid,
      creatorDisplayName: creatorDisplayName ?? this.creatorDisplayName,
      createdAt: createdAt ?? this.createdAt,
      lastEditorUid: lastEditorUid ?? this.lastEditorUid,
      lastEditorDisplayName: lastEditorDisplayName ?? this.lastEditorDisplayName,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
    );
  }
}

