import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/notifications/providers/notification_providers.dart';
import '../theme/app_colors.dart';
import 'notification_bell_button.dart';

/// Bottom-nav shell for authenticated members.
class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fcmServiceProvider).init(context);
    });
  }

  void _onBranchSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    if (isWide) {
      return _DesktopShell(
        navigationShell: widget.navigationShell,
        currentIndex: widget.navigationShell.currentIndex,
        onBranchSelected: _onBranchSelected,
      );
    }
    return _MobileShell(
      navigationShell: widget.navigationShell,
      currentIndex: widget.navigationShell.currentIndex,
      onBranchSelected: _onBranchSelected,
    );
  }
}

// ── Mobile Shell ─────────────────────────────────────────────────────────────

class _MobileShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final int currentIndex;
  final void Function(int) onBranchSelected;

  const _MobileShell({
    required this.navigationShell,
    required this.currentIndex,
    required this.onBranchSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        height: 68,
        elevation: 0,
        selectedIndex: currentIndex,
        onDestinationSelected: onBranchSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.handshake_outlined),
            selectedIcon: Icon(Icons.handshake_rounded),
            label: 'Pledges',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── Desktop Shell ─────────────────────────────────────────────────────────────

class _DesktopShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  final int currentIndex;
  final void Function(int) onBranchSelected;

  const _DesktopShell({
    required this.navigationShell,
    required this.currentIndex,
    required this.onBranchSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          // ── Left Sidebar ─────────────────────────────────────────────────
          _MemberSidebar(
            currentIndex: currentIndex,
            onBranchSelected: onBranchSelected,
          ),
          // ── Main Content (max-width constrained) ─────────────────────────
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: navigationShell,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Member Sidebar ────────────────────────────────────────────────────────────

class _MemberSidebar extends ConsumerStatefulWidget {
  final int currentIndex;
  final void Function(int) onBranchSelected;

  const _MemberSidebar({
    required this.currentIndex,
    required this.onBranchSelected,
  });

  @override
  ConsumerState<_MemberSidebar> createState() => _MemberSidebarState();
}

class _MemberSidebarState extends ConsumerState<_MemberSidebar> {
  static const _navItems = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavItem(Icons.handshake_outlined, Icons.handshake_rounded, 'Pledges'),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, Color(0xFF0D1F4E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.25),
            blurRadius: 24,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // ── Brand Logo ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.goldLight.withValues(alpha: 0.25),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/ingc_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.church_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'IMPACT NATION',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'GOSPEL CENTER',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 9,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Notification Bell ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  NotificationBellButton(
                    iconColor: Colors.white.withValues(alpha: 0.8),
                    onTap: () => context.push('/home/notifications'),
                  ),
                  Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Divider ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              color: Colors.white.withValues(alpha: 0.1),
              height: 1,
            ),
          ),
          const SizedBox(height: 12),

          // ── Nav Items ─────────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = widget.currentIndex == index;
                return _SidebarNavTile(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => widget.onBranchSelected(index),
                );
              },
            ),
          ),

          // ── Sign Out ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
            child: _SidebarSignOutTile(),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar Nav Tile ──────────────────────────────────────────────────────────

class _SidebarNavTile extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarNavTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarNavTile> createState() => _SidebarNavTileState();
}

class _SidebarNavTileState extends State<_SidebarNavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isActive
                ? AppColors.goldLight.withValues(alpha: 0.18)
                : _hovered
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.transparent,
            border: isActive
                ? Border.all(
                    color: AppColors.goldLight.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: isActive
                      ? AppColors.goldBright
                      : Colors.transparent,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                isActive ? widget.item.selectedIcon : widget.item.icon,
                color: isActive
                    ? AppColors.goldBright
                    : Colors.white
                        .withValues(alpha: _hovered ? 0.9 : 0.65),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                widget.item.label,
                style: TextStyle(
                  color: isActive
                      ? Colors.white
                      : Colors.white
                          .withValues(alpha: _hovered ? 0.9 : 0.65),
                  fontSize: 14,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w400,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sign Out Tile ─────────────────────────────────────────────────────────────

class _SidebarSignOutTile extends ConsumerStatefulWidget {
  const _SidebarSignOutTile();

  @override
  ConsumerState<_SidebarSignOutTile> createState() =>
      _SidebarSignOutTileState();
}

class _SidebarSignOutTileState extends ConsumerState<_SidebarSignOutTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          await ref.read(authControllerProvider.notifier).signOut();
          if (context.mounted) context.go('/login');
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _hovered
                ? Colors.red.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              const SizedBox(width: 15),
              Icon(
                Icons.logout_rounded,
                color: Colors.white
                    .withValues(alpha: _hovered ? 0.9 : 0.5),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.white
                      .withValues(alpha: _hovered ? 0.9 : 0.55),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Nav Item Data ─────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem(this.icon, this.selectedIcon, this.label);
}

