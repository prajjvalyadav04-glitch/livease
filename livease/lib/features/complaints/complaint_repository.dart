import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../auth/app_user.dart';
import 'complaint.dart';

class ComplaintRepository {
  ComplaintRepository(this._db, this._storage);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('complaints');

  List<Complaint> _sorted(QuerySnapshot<Map<String, dynamic>> snap) {
    final items = snap.docs.map(Complaint.fromDoc).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Stream<List<Complaint>> watchMine(String residentId) => _col
      .where('residentId', isEqualTo: residentId)
      .snapshots()
      .map(_sorted);

  /// Admin view: every complaint in the society.
  Stream<List<Complaint>> watchAll() => _col.snapshots().map(_sorted);

  Future<void> create({
    required AppUser resident,
    required String category,
    required String title,
    required String description,
    Uint8List? photoBytes,
  }) async {
    final ref = _col.doc();

    String? photoUrl;
    if (photoBytes != null) {
      final file = _storage.ref('complaints/${resident.uid}/${ref.id}.jpg');
      await file.putData(
        photoBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      photoUrl = await file.getDownloadURL();
    }

    await ref.set({
      'residentId': resident.uid,
      'residentName': resident.name,
      'flat': resident.flat,
      'category': category,
      'title': title,
      'description': description,
      'status': ComplaintStatus.open.key,
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin only (enforced by Firestore rules). The `notifyComplaintUpdate`
  /// Cloud Function pushes the change to the resident.
  Future<void> updateStatus(String id, ComplaintStatus status) {
    return _col.doc(id).update({
      'status': status.key,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final complaintRepositoryProvider = Provider<ComplaintRepository>(
  (ref) => ComplaintRepository(
    ref.watch(firestoreProvider),
    ref.watch(storageProvider),
  ),
);

final myComplaintsProvider = StreamProvider<List<Complaint>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const <Complaint>[]);
  return ref.watch(complaintRepositoryProvider).watchMine(uid);
});

final allComplaintsProvider = StreamProvider<List<Complaint>>(
  (ref) => ref.watch(complaintRepositoryProvider).watchAll(),
);
