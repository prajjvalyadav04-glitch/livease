import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/widgets.dart';
import '../auth/auth_repository.dart';
import 'visitor_pass.dart';
import 'visitor_repository.dart';

/// Guard view: scan a visitor's QR and allow or deny entry.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final raw = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (raw == null) return;

    final guard = ref.read(profileProvider).valueOrNull;
    if (guard == null) return;

    setState(() => _busy = true);
    try {
      final passId = VisitorPass.parseQr(raw);
      final result = passId == null
          ? const VerifyResult(VerifyStatus.notFound)
          : await ref
              .read(visitorRepositoryProvider)
              .verifyAndConsume(passId, guard);
      if (!mounted) return;
      await _showResult(result);
    } catch (e) {
      showSnack('Verification failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showResult(VerifyResult result) {
    final (icon, color, title, detail) = switch (result.status) {
      VerifyStatus.valid => (
          Icons.check_circle,
          Colors.green.shade700,
          'Allow entry',
          'Pass verified and marked as used.',
        ),
      VerifyStatus.alreadyUsed => (
          Icons.block,
          Colors.red.shade700,
          'Deny - already used',
          'This pass was already scanned.',
        ),
      VerifyStatus.expired => (
          Icons.timer_off,
          Colors.orange.shade800,
          'Deny - expired',
          'This pass is past its validity time.',
        ),
      VerifyStatus.notFound => (
          Icons.cancel,
          Colors.red.shade700,
          'Deny - invalid pass',
          'This is not a valid LivEase visitor pass.',
        ),
    };
    final pass = result.pass;

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(detail, textAlign: TextAlign.center),
            if (pass != null) ...[
              const Divider(height: 32),
              _row('Visitor', pass.visitorName),
              _row('Purpose', pass.purpose),
              _row('Visiting', '${pass.residentName} (Flat ${pass.flat})'),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Scan next'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error, child) => EmptyState(
            icon: Icons.no_photography_outlined,
            title: 'Camera unavailable',
            subtitle: 'Allow camera access in Settings to scan passes.',
          ),
        ),
        // Aiming frame.
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 32,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _busy ? 'Checking pass...' : 'Point the camera at the visitor\'s QR',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
