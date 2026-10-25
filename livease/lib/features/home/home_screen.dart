import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../amenities/amenities_screen.dart';
import '../auth/app_user.dart';
import '../auth/auth_repository.dart';
import '../complaints/complaints_screen.dart';
import '../notices/notices_screen.dart';
import '../visitors/scan_screen.dart';
import '../visitors/visitors_screen.dart';

class _HomeTab {
  const _HomeTab({
    required this.label,
    required this.icon,
    required this.page,
    this.fabRoute,
    this.fabLabel,
  });

  final String label;
  final IconData icon;
  final Widget page;
  final String? fabRoute;
  final String? fabLabel;
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  /// Each role gets its own set of tabs.
  List<_HomeTab> _tabsFor(AppUser user) {
    switch (user.role) {
      case UserRole.guard:
        return const [
          _HomeTab(
            label: 'Notices',
            icon: Icons.campaign_outlined,
            page: NoticesScreen(),
          ),
          _HomeTab(
            label: 'Scan',
            icon: Icons.qr_code_scanner,
            page: ScanScreen(),
          ),
        ];
      case UserRole.admin:
        return const [
          _HomeTab(
            label: 'Notices',
            icon: Icons.campaign_outlined,
            page: NoticesScreen(),
            fabRoute: '/notices/new',
            fabLabel: 'Post notice',
          ),
          _HomeTab(
            label: 'Complaints',
            icon: Icons.build_circle_outlined,
            page: ComplaintsScreen(adminView: true),
          ),
        ];
      case UserRole.resident:
        return const [
          _HomeTab(
            label: 'Notices',
            icon: Icons.campaign_outlined,
            page: NoticesScreen(),
          ),
          _HomeTab(
            label: 'Visitors',
            icon: Icons.badge_outlined,
            page: VisitorsScreen(),
            fabRoute: '/visitors/new',
            fabLabel: 'New pass',
          ),
          _HomeTab(
            label: 'Complaints',
            icon: Icons.build_circle_outlined,
            page: ComplaintsScreen(adminView: false),
            fabRoute: '/complaints/new',
            fabLabel: 'Raise issue',
          ),
          _HomeTab(
            label: 'Amenities',
            icon: Icons.fitness_center,
            page: AmenitiesScreen(),
          ),
        ];
    }
  }

  Future<void> _confirmSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need an OTP to sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authRepositoryProvider).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(profileProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tabs = _tabsFor(user);
    final index = _index.clamp(0, tabs.length - 1);
    final tab = tabs[index];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tab.label),
            Text(
              '${user.name}  |  ${user.flat}  |  ${user.role.name}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: _confirmSignOut,
          ),
        ],
      ),
      body: tab.page,
      floatingActionButton: tab.fabRoute == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push(tab.fabRoute!),
              icon: const Icon(Icons.add),
              label: Text(tab.fabLabel ?? 'Add'),
            ),
      bottomNavigationBar: tabs.length < 2
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final t in tabs)
                  NavigationDestination(icon: Icon(t.icon), label: t.label),
              ],
            ),
    );
  }
}
