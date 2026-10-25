import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/widgets.dart';
import 'visitor_pass.dart';

/// Shows the QR code for a pass. The resident shows or forwards this to the
/// visitor, who presents it at the gate.
class PassScreen extends StatelessWidget {
  const PassScreen({super.key, required this.pass});

  final VisitorPass pass;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Visitor pass')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  pass.visitorName,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('${pass.purpose}  |  Flat ${pass.flat}'),
                const SizedBox(height: 24),
                // QR codes need a light background to scan reliably, even in
                // dark mode.
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: pass.qrData,
                    version: QrVersions.auto,
                    size: 240,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Valid till ${kDateTimeFormat.format(pass.expiresAt)}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Single use - becomes invalid once scanned.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(
                      text: 'Visitor pass for ${pass.visitorName} '
                          '(Flat ${pass.flat}), valid till '
                          '${kDateTimeFormat.format(pass.expiresAt)}. '
                          'Pass ID: ${pass.id}',
                    ));
                    showSnack('Pass details copied');
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy details'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
