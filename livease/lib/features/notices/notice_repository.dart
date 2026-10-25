import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'notice.dart';

class NoticeRepository {
  NoticeRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('notices');

  Stream<List<Notice>> watchNotices() {
    return _col
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) {
      final notices = snap.docs.map(Notice.fromDoc).toList();
      // Pinned notices float to the top, newest first within each group.
      notices.sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      return notices;
    });
  }

  Future<void> create({
    required String title,
    required String body,
    required String authorName,
    required bool pinned,
  }) {
    return _col.add({
      'title': title,
      'body': body,
      'authorName': authorName,
      'pinned': pinned,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) => _col.doc(id).delete();
}

final noticeRepositoryProvider = Provider<NoticeRepository>(
  (ref) => NoticeRepository(ref.watch(firestoreProvider)),
);

final noticesProvider = StreamProvider<List<Notice>>(
  (ref) => ref.watch(noticeRepositoryProvider).watchNotices(),
);
