import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets.dart';
import 'auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  String? _verificationId;
  bool _loading = false;

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final digits = _phone.text.trim();
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      showSnack('Enter a valid 10-digit mobile number');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).sendOtp(
        phone: '+91$digits',
        onCodeSent: (id) {
          if (!mounted) return;
          setState(() {
            _verificationId = id;
            _loading = false;
          });
        },
        onError: (message) {
          if (!mounted) return;
          setState(() => _loading = false);
          showSnack(message);
        },
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showSnack(e.message ?? 'Could not send OTP');
    }
  }

  Future<void> _verify() async {
    final code = _otp.text.trim();
    if (code.length != 6 || _verificationId == null) {
      showSnack('Enter the 6-digit code');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).verifyOtp(_verificationId!, code);
      // The router redirects automatically once the auth state changes.
    } on FirebaseAuthException catch (e) {
      showSnack(e.message ?? 'Invalid code');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeNumber() {
    setState(() {
      _verificationId = null;
      _otp.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final codeSent = _verificationId != null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.apartment_rounded,
                      size: 72, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'LivEase',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your society, simplified',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const SizedBox(height: 40),
                  if (!codeSent) ...[
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      autofocus: true,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Mobile number',
                        prefixText: '+91  ',
                        counterText: '',
                      ),
                      onSubmitted: (_) => _sendOtp(),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _sendOtp,
                      child: _loading
                          ? const _ButtonSpinner()
                          : const Text('Send OTP'),
                    ),
                  ] else ...[
                    Text(
                      'Enter the 6-digit code sent to +91 ${_phone.text}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _otp,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, letterSpacing: 8),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'OTP',
                        counterText: '',
                      ),
                      onSubmitted: (_) => _verify(),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _verify,
                      child: _loading
                          ? const _ButtonSpinner()
                          : const Text('Verify & continue'),
                    ),
                    TextButton(
                      onPressed: _loading ? null : _changeNumber,
                      child: const Text('Change number'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
