import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets.dart';
import '../auth/auth_repository.dart';
import 'notice.dart';
import 'notice_repository.dart';

class NoticesScreen extends ConsumerWidget {
  const NoticesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notices = ref.watch(noticesProvider);
    final isAdmin = ref.watch(profileProvider).valueOrNull?.isAdmin ?? false;

    return AsyncListView<Notice>(
      value: notices,
      emptyIcon: Icons.campaign_outlined,
      emptyTitle: 'No notices yet',
      emptySubtitle: 'Announcements from the society office will show up here.',
      itemBuilder: (context, notice) => _NoticeCard(
        notice: notice,
        canDelete: isAdmin,
        onDelete: () => _confirmDelete(context, ref, notice),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Notice notice,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete notice?'),
        content: Text(notice.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(noticeRepositoryProvider).delete(notice.id);
    }
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.notice,
    required this.canDelete,
    required this.onDelete,
  });

  final Notice notice;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (notice.pinned) ...[
                  Icon(Icons.push_pin, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    notice.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (canDelete)
                  IconButton(
                    tooltip: 'Delete',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(notice.body),
            const SizedBox(height: 12),
            Text(
              '${notice.authorName}  |  ${kDateTimeFormat.format(notice.createdAt)}',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
