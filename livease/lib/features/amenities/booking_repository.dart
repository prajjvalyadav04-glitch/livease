import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../auth/app_user.dart';
import 'amenity.dart';

final DateFormat kIsoDay = DateFormat('yyyy-MM-dd');

class BookingRepository {
  BookingRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('bookings');

  /// All bookings for one amenity on one day (used to grey out taken slots).
  Stream<List<Booking>> watchDay(String amenityId, String date) {
    return _col
        .where('amenityId', isEqualTo: amenityId)
        .where('date', isEqualTo: date)
        .snapshots()
        .map((snap) => snap.docs.map(Booking.fromDoc).toList());
  }

  Stream<List<Booking>> watchMine(String residentId) {
    return _col
        .where('residentId', isEqualTo: residentId)
        .snapshots()
        .map((snap) {
      final items = snap.docs.map(Booking.fromDoc).toList();
      items.sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        return byDate != 0 ? byDate : a.slot.compareTo(b.slot);
      });
      return items;
    });
  }

  /// Books a slot, failing with [SlotTakenException] if it is already taken.
  ///
  /// The document id is derived from (amenity, date, slot), so two residents
  /// racing for the same slot target the same document. The transaction checks
  /// it does not exist yet, and the Firestore rules only allow `create` (never
  /// update) on bookings, so a double booking is impossible even from a
  /// modified client.
  Future<void> book({
    required AppUser resident,
    required Amenity amenity,
    required String date,
    required String slot,
  }) {
    final id = Booking.idFor(amenity.id, date, slot);
    final ref = _col.doc(id);

    return _db.runTransaction<void>((tx) async {
      final existing = await tx.get(ref);
      if (existing.exists) throw const SlotTakenException();

      tx.set(ref, {
        'amenityId': amenity.id,
        'amenityName': amenity.name,
        'residentId': resident.uid,
        'residentName': resident.name,
        'flat': resident.flat,
        'date': date,
        'slot': slot,
        'slotKey': Booking.slotKey(slot),
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> cancel(String bookingId) => _col.doc(bookingId).delete();
}

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepository(ref.watch(firestoreProvider)),
);

final myBookingsProvider = StreamProvider<List<Booking>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const <Booking>[]);
  return ref.watch(bookingRepositoryProvider).watchMine(uid);
});

typedef DayKey = ({String amenityId, String date});

final dayBookingsProvider =
    StreamProvider.autoDispose.family<List<Booking>, DayKey>((ref, key) {
  return ref
      .watch(bookingRepositoryProvider)
      .watchDay(key.amenityId, key.date);
});
