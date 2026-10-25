import 'package:flutter_test/flutter_test.dart';
import 'package:livease/features/amenities/amenity.dart';

void main() {
  group('Booking ids', () {
    test('slotKey strips colons and spaces', () {
      expect(Booking.slotKey('06:00 - 08:00'), '0600-0800');
    });

    test('same amenity/day/slot always gives the same id', () {
      final a = Booking.idFor('gym', '2026-11-02', '06:00 - 08:00');
      final b = Booking.idFor('gym', '2026-11-02', '06:00 - 08:00');
      expect(a, b);
      expect(a, 'gym_2026-11-02_0600-0800');
    });

    test('different slot or day gives a different id', () {
      final base = Booking.idFor('gym', '2026-11-02', '06:00 - 08:00');
      expect(Booking.idFor('gym', '2026-11-02', '08:00 - 10:00'), isNot(base));
      expect(Booking.idFor('gym', '2026-11-03', '06:00 - 08:00'), isNot(base));
      expect(Booking.idFor('pool', '2026-11-02', '06:00 - 08:00'), isNot(base));
    });
  });

  group('Slots', () {
    test('slotStartHour reads the start hour', () {
      expect(slotStartHour('16:00 - 18:00'), 16);
      expect(slotStartHour('06:00 - 08:00'), 6);
    });

    test('every slot parses', () {
      for (final slot in kSlots) {
        expect(() => slotStartHour(slot), returnsNormally);
      }
    });
  });
}
