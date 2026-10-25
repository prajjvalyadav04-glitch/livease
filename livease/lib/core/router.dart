import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/amenities/amenity.dart';
import '../features/amenities/book_screen.dart';
import '../features/auth/auth_repository.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/setup_screen.dart';
import '../features/complaints/new_complaint_screen.dart';
import '../features/home/home_screen.dart';
import '../features/notices/new_notice_screen.dart';
import '../features/visitors/new_visitor_screen.dart';
import '../features/visitors/pass_screen.dart';
import '../features/visitors/visitor_pass.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Re-evaluate redirects whenever auth or profile state changes.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, __) => refresh.value++);
  ref.listen(profileProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final profile = ref.read(profileProvider);
      final location = state.matchedLocation;

      if (auth.isLoading) return '/splash';

      // Signed out -> login.
      if (auth.valueOrNull == null) {
        return location == '/login' ? null : '/login';
      }

      // Signed in but profile still loading -> splash.
      if (profile.isLoading) return '/splash';

      // Signed in, no profile yet -> setup.
      if (profile.valueOrNull == null) {
        return location == '/setup' ? null : '/setup';
      }

      // Fully onboarded: keep users out of the auth screens.
      if (location == '/login' || location == '/setup' || location == '/splash') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const _SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/setup', builder: (_, __) => const SetupScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/notices/new',
        builder: (_, __) => const NewNoticeScreen(),
      ),
      GoRoute(
        path: '/visitors/new',
        builder: (_, __) => const NewVisitorScreen(),
      ),
      GoRoute(
        path: '/visitors/pass',
        // The pass is handed over via `extra`; fall back home if it is missing
        // (e.g. after a process restart).
        redirect: (context, state) => state.extra is VisitorPass ? null : '/home',
        builder: (_, state) => PassScreen(pass: state.extra! as VisitorPass),
      ),
      GoRoute(
        path: '/complaints/new',
        builder: (_, __) => const NewComplaintScreen(),
      ),
      GoRoute(
        path: '/amenities/book',
        redirect: (context, state) => state.extra is Amenity ? null : '/home',
        builder: (_, state) => BookScreen(amenity: state.extra! as Amenity),
      ),
    ],
  );
});

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
