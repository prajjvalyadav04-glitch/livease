import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Amenity {
  const Amenity({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });

  final String id;
  final String name;
  final IconData icon;
  final String description;
}

const List<Amenity> kAmenities = [
  Amenity(
    id: 'clubhouse',
    name: 'Clubhouse',
    icon: Icons.weekend_outlined,
    description: 'Parties, meetings and community events',
  ),
  Amenity(
    id: 'gym',
    name: 'Gym',
    icon: Icons.fitness_center,
    description: 'Fully equipped fitness centre',
  ),
  Amenity(
    id: 'hall',
    name: 'Banquet Hall',
    icon: Icons.celebration_outlined,
    description: 'Large hall for functions and celebrations',
  ),
  Amenity(
    id: 'court',
    name: 'Tennis Court',
    icon: Icons.sports_tennis,
    description: 'Floodlit court, rackets on request',
  ),
  Amenity(
    id: 'pool',
    name: 'Swimming Pool',
    icon: Icons.pool,
    description: 'Adults and kids pool',
  ),
];

/// Bookable two-hour slots.
const List<String> kSlots = [
  '06:00 - 08:00',
  '08:00 - 10:00',
  '10:00 - 12:00',
  '16:00 - 18:00',
  '18:00 - 20:00',
  '20:00 - 22:00',
];

/// Hour (24h) at which a slot starts, e.g. '16:00 - 18:00' -> 16.
int slotStartHour(String slot) => int.parse(slot.substring(0, 2));

class Booking {
  const Booking({
    required this.id,
    required this.amenityId,
    required this.amenityName,
    required this.residentId,
    required this.residentName,
    required this.flat,
    required this.date,
    required this.slot,
  });

  final String id;
  final String amenityId;
  final String amenityName;
  final String residentId;
  final String residentName;
  final String flat;

  /// Calendar day as `yyyy-MM-dd`.
  final String date;
  final String slot;

  /// '06:00 - 08:00' -> '0600-0800'
  static String slotKey(String slot) => slot.replaceAll(RegExp(r'[: ]'), '');

  /// Deterministic document id. Because one (amenity, day, slot) maps to one
  /// document id, Firestore itself guarantees there can only ever be one
  /// booking per slot - the booking transaction and the security rules both
  /// rely on this.
  static String idFor(String amenityId, String date, String slot) =>
      '${amenityId}_${date}_${slotKey(slot)}';

  factory Booking.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Booking(
      id: doc.id,
      amenityId: (d['amenityId'] as String?) ?? '',
      amenityName: (d['amenityName'] as String?) ?? '',
      residentId: (d['residentId'] as String?) ?? '',
      residentName: (d['residentName'] as String?) ?? '',
      flat: (d['flat'] as String?) ?? '',
      date: (d['date'] as String?) ?? '',
      slot: (d['slot'] as String?) ?? '',
    );
  }
}

class SlotTakenException implements Exception {
  const SlotTakenException();

  @override
  String toString() => 'That slot was just booked by someone else.';
}
