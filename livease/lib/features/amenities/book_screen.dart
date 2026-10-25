import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../auth/auth_repository.dart';
import 'amenity.dart';
import 'booking_repository.dart';

/// Pick a day (next 14 days) and a free slot for one amenity.
class BookScreen extends ConsumerStatefulWidget {
  const BookScreen({super.key, required this.amenity});

  final Amenity amenity;

  @override
  ConsumerState<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends ConsumerState<BookScreen> {
  static const int _daysAhead = 14;

  late final List<DateTime> _days;
  int _dayIndex = 0;
  String? _slot;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _days = [for (var i = 0; i < _daysAhead; i++) today.add(Duration(days: i))];
  }

  String get _date => kIsoDay.format(_days[_dayIndex]);

  /// A slot is unavailable if it is already booked, or (for today) already
  /// started.
  bool _isPast(String slot) {
    final isToday = _dayIndex == 0;
    return isToday && slotStartHour(slot) <= DateTime.now().hour;
  }

  Future<void> _confirm() async {
    final slot = _slot;
    final resident = ref.read(profileProvider).valueOrNull;
    if (slot == null || resident == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(bookingRepositoryProvider).book(
            resident: resident,
            amenity: widget.amenity,
            date: _date,
            slot: slot,
          );
      if (!mounted) return;
      showSnack('Booked ${widget.amenity.name}, $slot');
      context.pop();
    } on SlotTakenException catch (e) {
      showSnack(e.toString());
      if (mounted) {
        setState(() {
          _slot = null;
          _saving = false;
        });
      }
    } catch (e) {
      showSnack('Booking failed: $e');
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    final dayBookings = ref.watch(
      dayBookingsProvider((amenityId: widget.amenity.id, date: _date)),
    );

    return Scaffold(
      appBar: AppBar(title: Text('Book ${widget.amenity.name}')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Choose a day', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _days.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final d = _days[i];
                        return ChoiceChip(
                          selected: i == _dayIndex,
                          onSelected: (_) => setState(() {
                            _dayIndex = i;
                            _slot = null;
                          }),
                          label: SizedBox(
                            width: 44,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(DateFormat('EEE').format(d),
                                    style: theme.textTheme.labelSmall),
                                Text(
                                  '${d.day}',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(DateFormat('MMM').format(d),
                                    style: theme.textTheme.labelSmall),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Choose a slot', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  dayBookings.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => ErrorState(message: '$e'),
                    data: (bookings) {
                      final taken = {for (final b in bookings) b.slot: b};
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final slot in kSlots)
                            _SlotChip(
                              slot: slot,
                              selected: _slot == slot,
                              state: taken[slot] != null
                                  ? (taken[slot]!.residentId == uid
                                      ? _SlotState.mine
                                      : _SlotState.taken)
                                  : (_isPast(slot)
                                      ? _SlotState.past
                                      : _SlotState.free),
                              onTap: () => setState(() => _slot = slot),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Greyed-out slots are already booked or have passed.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (_slot == null || _saving) ? null : _confirm,
                  icon: const Icon(Icons.event_available),
                  label: Text(_saving ? 'Booking...' : 'Confirm booking'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _SlotState { free, taken, mine, past }

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.slot,
    required this.selected,
    required this.state,
    required this.onTap,
  });

  final String slot;
  final bool selected;
  final _SlotState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = switch (state) {
      _SlotState.free || _SlotState.past => slot,
      _SlotState.taken => '$slot  (booked)',
      _SlotState.mine => '$slot  (yours)',
    };
    final enabled = state == _SlotState.free;

    return ChoiceChip(
      label: Text(label),
      selected: selected && enabled,
      onSelected: enabled ? (_) => onTap() : null,
    );
  }
}
