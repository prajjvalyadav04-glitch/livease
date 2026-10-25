import 'package:cloud_firestore/cloud_firestore.dart';

class Notice {
  const Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.authorName,
    required this.createdAt,
    required this.pinned,
  });

  final String id;
  final String title;
  final String body;
  final String authorName;
  final DateTime createdAt;
  final bool pinned;

  factory Notice.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Notice(
      id: doc.id,
      title: (d['title'] as String?) ?? '',
      body: (d['body'] as String?) ?? '',
      authorName: (d['authorName'] as String?) ?? 'Management',
      // createdAt is null for a moment right after a local write while the
      // server timestamp is still pending.
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pinned: (d['pinned'] as bool?) ?? false,
    );
  }
}
