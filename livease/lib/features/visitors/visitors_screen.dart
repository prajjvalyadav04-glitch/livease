import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets.dart';
import 'visitor_pass.dart';
import 'visitor_repository.dart';

/// Resident view: list of the visitor passes they have created.
class VisitorsScreen extends ConsumerWidget {
  const VisitorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passes = ref.watch(myPassesProvider);

    return AsyncListView<VisitorPass>(
      value: passes,
      emptyIcon: Icons.badge_outlined,
      emptyTitle: 'No visitor passes',
      emptySubtitle:
          'Pre-approve a guest, delivery or cab and share the QR with them.',
      itemBuilder: (context, pass) => _PassTile(pass: pass),
    );
  }
}

class _PassTile extends StatelessWidget {
  const _PassTile({required this.pass});

  final VisitorPass pass;

  @override
  Widget build(BuildContext context) {
    final status = pass.status;
    final (label, color) = switch (status) {
      PassStatus.active => ('Active', Colors.green.shade700),
      PassStatus.used => ('Used', Colors.blueGrey),
      PassStatus.expired => ('Expired', Colors.red.shade700),
    };

    return Card.outlined(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: Text(pass.visitorName),
        subtitle: Text(
          '${pass.purpose}\nValid till ${kDateTimeFormat.format(pass.expiresAt)}',
        ),
        isThreeLine: true,
        trailing: StatusChip(label: label, color: color),
        onTap: status == PassStatus.active
            ? () => context.push('/visitors/pass', extra: pass)
            : null,
      ),
    );
  }
}
