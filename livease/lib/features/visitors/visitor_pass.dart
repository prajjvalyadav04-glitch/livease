import 'package:cloud_firestore/cloud_firestore.dart';

enum PassStatus { active, used, expired }

class VisitorPass {
  const VisitorPass({
    required this.id,
    required this.residentId,
    required this.residentName,
    required this.flat,
    required this.visitorName,
    required this.purpose,
    required this.expiresAt,
    required this.createdAt,
    this.used = false,
    this.usedAt,
  });

  final String id;
  final String residentId;
  final String residentName;
  final String flat;
  final String visitorName;
  final String purpose;
  final DateTime expiresAt;
  final DateTime createdAt;
  final bool used;
  final DateTime? usedAt;

  static const String _qrPrefix = 'livease:pass:';

  /// Passes are single-use: once the guard scans one it is marked used.
  /// Expiry is computed from [expiresAt] so no background job is needed.
  PassStatus statusAt(DateTime now) {
    if (used) return PassStatus.used;
    if (now.isAfter(expiresAt)) return PassStatus.expired;
    return PassStatus.active;
  }

  PassStatus get status => statusAt(DateTime.now());
  bool get isExpired => status == PassStatus.expired;

  /// Text encoded in the QR code.
  String get qrData => '$_qrPrefix$id';

  /// Extracts the pass id from scanned QR text, or null if the code is not a
  /// LivEase pass.
  static String? parseQr(String? raw) {
    if (raw == null || !raw.startsWith(_qrPrefix)) return null;
    final id = raw.substring(_qrPrefix.length).trim();
    return id.isEmpty ? null : id;
  }

  factory VisitorPass.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return VisitorPass(
      id: doc.id,
      residentId: (d['residentId'] as String?) ?? '',
      residentName: (d['residentName'] as String?) ?? '',
      flat: (d['flat'] as String?) ?? '',
      visitorName: (d['visitorName'] as String?) ?? '',
      purpose: (d['purpose'] as String?) ?? '',
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      used: d['status'] == 'used',
      usedAt: (d['usedAt'] as Timestamp?)?.toDate(),
    );
  }
}
