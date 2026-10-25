import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/widgets.dart';
import '../auth/auth_repository.dart';
import 'complaint.dart';
import 'complaint_repository.dart';

class NewComplaintScreen extends ConsumerStatefulWidget {
  const NewComplaintScreen({super.key});

  @override
  ConsumerState<NewComplaintScreen> createState() => _NewComplaintScreenState();
}

class _NewComplaintScreenState extends ConsumerState<NewComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _picker = ImagePicker();
  String _category = kComplaintCategories.first;
  Uint8List? _photo;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      // Resize + compress at pick time so uploads stay small on mobile data.
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 70,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _photo = bytes);
    } catch (e) {
      showSnack('Could not get photo: $e');
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final resident = ref.read(profileProvider).valueOrNull;
    if (resident == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(complaintRepositoryProvider).create(
            resident: resident,
            category: _category,
            title: _title.text.trim(),
            description: _description.text.trim(),
            photoBytes: _photo,
          );
      if (!mounted) return;
      showSnack('Complaint submitted');
      context.pop();
    } catch (e) {
      showSnack('Could not submit complaint: $e');
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Raise an issue')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final c in kComplaintCategories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Short title',
                  hintText: 'e.g. Water leakage in bathroom',
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 3) ? 'Enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                minLines: 4,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Describe the problem',
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Add a few more details (10+ characters)'
                    : null,
              ),
              const SizedBox(height: 16),
              if (_photo != null)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _photo!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Remove photo',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _photo = null),
                    ),
                  ],
                )
              else
                OutlinedButton.icon(
                  onPressed: _showPhotoOptions,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Attach a photo (optional)'),
                ),
              const SizedBox(height: 8),
              Text(
                'A clear photo helps the maintenance team fix it faster.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: const Icon(Icons.send),
                label: Text(_saving ? 'Submitting...' : 'Submit complaint'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
