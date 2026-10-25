import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets.dart';
import '../auth/auth_repository.dart';
import 'notice_repository.dart';

/// Admin-only screen for posting a society notice. Creating the document
/// triggers the `notifyNewNotice` Cloud Function, which sends the push.
class NewNoticeScreen extends ConsumerStatefulWidget {
  const NewNoticeScreen({super.key});

  @override
  ConsumerState<NewNoticeScreen> createState() => _NewNoticeScreenState();
}

class _NewNoticeScreenState extends ConsumerState<NewNoticeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _pinned = false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final admin = ref.read(profileProvider).valueOrNull;
    if (admin == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(noticeRepositoryProvider).create(
            title: _title.text.trim(),
            body: _body.text.trim(),
            authorName: admin.name,
            pinned: _pinned,
          );
      if (!mounted) return;
      showSnack('Notice posted');
      context.pop();
    } catch (e) {
      showSnack('Could not post notice: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a notice')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    (v == null || v.trim().length < 3) ? 'Enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _body,
                minLines: 5,
                maxLines: 10,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 5) ? 'Enter a message' : null,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pin to top'),
                value: _pinned,
                onChanged: (v) => setState(() => _pinned = v),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.send),
                label: Text(_saving ? 'Posting...' : 'Post & notify residents'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
