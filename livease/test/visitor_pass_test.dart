import 'package:flutter_test/flutter_test.dart';
import 'package:livease/features/visitors/visitor_pass.dart';

VisitorPass _pass({
  String id = 'abc123',
  DateTime? expiresAt,
  bool used = false,
}) {
  return VisitorPass(
    id: id,
    residentId: 'u1',
    residentName: 'Asha',
    flat: 'B-402',
    visitorName: 'Ravi',
    purpose: 'Guest',
    expiresAt: expiresAt ?? DateTime(2026, 1, 1, 12),
    createdAt: DateTime(2026, 1, 1, 10),
    used: used,
  );
}

void main() {
  group('VisitorPass status', () {
    test('is active before expiry', () {
      final pass = _pass();
      expect(pass.statusAt(DateTime(2026, 1, 1, 11)), PassStatus.active);
    });

    test('is expired after expiry', () {
      final pass = _pass();
      expect(pass.statusAt(DateTime(2026, 1, 1, 13)), PassStatus.expired);
    });

    test('used wins over expired', () {
      final pass = _pass(used: true);
      expect(pass.statusAt(DateTime(2026, 1, 1, 13)), PassStatus.used);
    });
  });

  group('VisitorPass QR payload', () {
    test('round-trips the pass id', () {
      final pass = _pass(id: 'xyz789');
      expect(VisitorPass.parseQr(pass.qrData), 'xyz789');
    });

    test('rejects foreign QR codes', () {
      expect(VisitorPass.parseQr('https://example.com'), isNull);
      expect(VisitorPass.parseQr(null), isNull);
      expect(VisitorPass.parseQr('livease:pass:'), isNull);
    });
  });
}
