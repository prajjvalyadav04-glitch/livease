import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets.dart';
import 'complaint.dart';
import 'complaint_repository.dart';

/// Residents see their own complaints; admins see all and can change status.
class ComplaintsScreen extends ConsumerWidget {
  const ComplaintsScreen({super.key, required this.adminView});

  final bool adminView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaints = ref.watch(
      adminView ? allComplaintsProvider : myComplaintsProvider,
    );

    return AsyncListView<Complaint>(
      value: complaints,
      emptyIcon: Icons.build_circle_outlined,
      emptyTitle: adminView ? 'No complaints' : 'No complaints raised',
      emptySubtitle: adminView
          ? 'Issues raised by residents will appear here.'
          : 'Something broken? Tap "Raise issue" to report it.',
      itemBuilder: (context, c) => _ComplaintTile(
        complaint: c,
        adminView: adminView,
      ),
    );
  }
}

class _ComplaintTile extends ConsumerWidget {
  const _ComplaintTile({required this.complaint, required this.adminView});

  final Complaint complaint;
  final bool adminView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = complaint;
    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetails(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (c.photoUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: c.photoUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const SizedBox(
                      width: 64,
                      height: 64,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => const SizedBox(
                      width: 64,
                      height: 64,
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(label: c.status.label, color: c.status.color),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        c.category,
                        if (adminView) '${c.residentName} (${c.flat})',
                        kDateTimeFormat.format(c.createdAt),
                      ].join('  |  '),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _ComplaintSheet(
        complaint: complaint,
        adminView: adminView,
        onStatusChanged: (status) async {
          Navigator.pop(sheetContext);
          try {
            await ref
                .read(complaintRepositoryProvider)
                .updateStatus(complaint.id, status);
            showSnack('Marked as ${status.label.toLowerCase()}');
          } catch (e) {
            showSnack('Could not update status: $e');
          }
        },
      ),
    );
  }
}

class _ComplaintSheet extends StatelessWidget {
  const _ComplaintSheet({
    required this.complaint,
    required this.adminView,
    required this.onStatusChanged,
  });

  final Complaint complaint;
  final bool adminView;
  final ValueChanged<ComplaintStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = complaint;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(c.title, style: theme.textTheme.titleLarge),
                ),
                StatusChip(label: c.status.label, color: c.status.color),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${c.category}  |  ${c.residentName} (${c.flat})  |  '
              '${kDateTimeFormat.format(c.createdAt)}',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 16),
            Text(c.description),
            if (c.photoUrl != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: c.photoUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SizedBox(
                    height: 160,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _Timeline(current: c.status),
            if (adminView) ...[
              const SizedBox(height: 20),
              Text('Update status', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final s in ComplaintStatus.values)
                    ChoiceChip(
                      label: Text(s.label),
                      selected: s == c.status,
                      onSelected:
                          s == c.status ? null : (_) => onStatusChanged(s),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Open -> In progress -> Resolved progress indicator.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.current});

  final ComplaintStatus current;

  @override
  Widget build(BuildContext context) {
    final steps = ComplaintStatus.values;
    final reached = steps.indexOf(current);
    final theme = Theme.of(context);

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Column(
            children: [
              Icon(
                i <= reached ? Icons.check_circle : Icons.radio_button_unchecked,
                color: i <= reached
                    ? steps[reached].color
                    : theme.colorScheme.outline,
              ),
              const SizedBox(height: 4),
              Text(steps[i].label, style: theme.textTheme.labelSmall),
            ],
          ),
          if (i < steps.length - 1)
            Expanded(
              child: Divider(
                thickness: 2,
                color: i < reached
                    ? steps[reached].color
                    : theme.colorScheme.outlineVariant,
              ),
            ),
        ],
      ],
    );
  }
}
