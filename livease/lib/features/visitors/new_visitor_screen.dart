import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets.dart';
import '../auth/auth_repository.dart';
import 'visitor_repository.dart';

const List<String> kPurposes = ['Guest', 'Delivery', 'Cab / Taxi', 'Service'];

const Map<String, Duration> kValidity = {
  '2 hours': Duration(hours: 2),
  '6 hours': Duration(hours: 6),
  '24 hours': Duration(hours: 24),
};

class NewVisitorScreen extends ConsumerStatefulWidget {
  const NewVisitorScreen({super.key});

  @override
  ConsumerState<NewVisitorScreen> createState() => _NewVisitorScreenState();
}

class _NewVisitorScreenState extends ConsumerState<NewVisitorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _purpose = kPurposes.first;
  String _validity = kValidity.keys.first;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final resident = ref.read(profileProvider).valueOrNull;
    if (resident == null) return;

    setState(() => _saving = true);
    try {
      final pass = await ref.read(visitorRepositoryProvider).create(
            resident: resident,
            visitorName: _name.text.trim(),
            purpose: _purpose,
            validFor: kValidity[_validity]!,
          );
      if (!mounted) return;
      context.pushReplacement('/visitors/pass', extra: pass);
    } catch (e) {
      showSnack('Could not create pass: $e');
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('New visitor pass')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Visitor name'),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Enter the visitor name'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _purpose,
                decoration: const InputDecoration(labelText: 'Purpose'),
                items: [
                  for (final p in kPurposes)
                    DropdownMenuItem(value: p, child: Text(p)),
                ],
                onChanged: (v) => setState(() => _purpose = v ?? _purpose),
              ),
              const SizedBox(height: 20),
              Text('Valid for', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  for (final k in kValidity.keys)
                    ButtonSegment(value: k, label: Text(k)),
                ],
                selected: {_validity},
                onSelectionChanged: (s) => setState(() => _validity = s.first),
              ),
              const SizedBox(height: 8),
              Text(
                'The pass works once. After the guard scans it, it cannot be '
                'reused.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _create,
                icon: const Icon(Icons.qr_code_2),
                label: Text(_saving ? 'Creating...' : 'Generate QR pass'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
