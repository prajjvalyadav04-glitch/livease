import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'core/widgets.dart';
import 'features/auth/auth_repository.dart';
import 'services/notification_service.dart';

class LivEaseApp extends ConsumerWidget {
  const LivEaseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Register for push notifications once a signed-in user has a profile.
    ref.listen(profileProvider, (previous, next) {
      final profile = next.valueOrNull;
      if (profile != null) {
        ref.read(notificationServiceProvider).init(profile.uid);
      }
    });

    return MaterialApp.router(
      title: 'LivEase',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      scaffoldMessengerKey: rootMessengerKey,
      routerConfig: router,
    );
  }
}
