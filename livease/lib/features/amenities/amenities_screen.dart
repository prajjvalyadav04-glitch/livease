import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets.dart';
import 'amenity.dart';
import 'booking_repository.dart';

class AmenitiesScreen extends ConsumerWidget {
  const AmenitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bookings = ref.watch(myBookingsProvider);
    final today = kIsoDay.format(DateTime.now());

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text('Book a facility', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final amenity in kAmenities)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card.outlined(
              child: ListTile(
                leading: CircleAvatar(child: Icon(amenity.icon)),
                title: Text(amenity.name),
                subtitle: Text(amenity.description),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/amenities/book', extra: amenity),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text('My upcoming bookings', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        bookings.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Could not load bookings: $e'),
          data: (all) {
            final upcoming = all.where((b) => b.date.compareTo(today) >= 0);
            if (upcoming.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Nothing booked yet.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              );
            }
            return Column(
              children: [
                for (final b in upcoming)
                  Card.outlined(
                    child: ListTile(
                      leading: const Icon(Icons.event_available),
                      title: Text(b.amenityName),
                      subtitle: Text(
                        '${kDateFormat.format(DateTime.parse(b.date))}\n${b.slot}',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        tooltip: 'Cancel booking',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmCancel(context, ref, b),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: Text('${booking.amenityName}, ${booking.date}, ${booking.slot}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(bookingRepositoryProvider).cancel(booking.id);
      showSnack('Booking cancelled');
    } catch (e) {
      showSnack('Could not cancel: $e');
    }
  }
}
