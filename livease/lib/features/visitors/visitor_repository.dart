import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../auth/app_user.dart';
import 'visitor_pass.dart';

enum VerifyStatus { valid, alreadyUsed, expired, notFound }

class VerifyResult {
  const VerifyResult(this.status, [this.pass]);

  final VerifyStatus status;
  final VisitorPass? pass;
}

class VisitorRepository {
  VisitorRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('visitor_passes');

  /// A resident's own passes, newest first. Sorted on the client so no
  /// composite Firestore index is needed.
  Stream<List<VisitorPass>> watchMine(String residentId) {
    return _col
        .where('residentId', isEqualTo: residentId)
        .snapshots()
        .map((snap) {
      final passes = snap.docs.map(VisitorPass.fromDoc).toList();
      passes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return passes;
    });
  }

  Future<VisitorPass> create({
    required AppUser resident,
    required String visitorName,
    required String purpose,
    required Duration validFor,
  }) async {
    final ref = _col.doc();
    final now = DateTime.now();
    final expiresAt = now.add(validFor);

    await ref.set({
      'residentId': resident.uid,
      'residentName': resident.name,
      'flat': resident.flat,
      'visitorName': visitorName,
      'purpose': purpose,
      'status': 'active',
      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return VisitorPass(
      id: ref.id,
      residentId: resident.uid,
      residentName: resident.name,
      flat: resident.flat,
      visitorName: visitorName,
      purpose: purpose,
      expiresAt: expiresAt,
      createdAt: now,
    );
  }

  /// Validates a scanned pass and marks it used in a single transaction, so
  /// two guards scanning the same code at once cannot both let the visitor in.
  Future<VerifyResult> verifyAndConsume(String passId, AppUser guard) {
    final ref = _col.doc(passId);
    return _db.runTransaction<VerifyResult>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return const VerifyResult(VerifyStatus.notFound);

      final pass = VisitorPass.fromDoc(snap);
      if (pass.used) return VerifyResult(VerifyStatus.alreadyUsed, pass);
      if (pass.isExpired) return VerifyResult(VerifyStatus.expired, pass);

      tx.update(ref, {
        'status': 'used',
        'usedAt': FieldValue.serverTimestamp(),
        'verifiedBy': guard.uid,
      });
      return VerifyResult(VerifyStatus.valid, pass);
    });
  }
}

final visitorRepositoryProvider = Provider<VisitorRepository>(
  (ref) => VisitorRepository(ref.watch(firestoreProvider)),
);

final myPassesProvider = StreamProvider<List<VisitorPass>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const <VisitorPass>[]);
  return ref.watch(visitorRepositoryProvider).watchMine(uid);
});
