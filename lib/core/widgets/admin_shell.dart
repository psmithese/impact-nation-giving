import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/domain/models/app_user.dart';
import '../../features/notifications/providers/notification_providers.dart';
import '../../features/members/providers/member_providers.dart';
import '../../core/theme/app_colors.dart';
import 'adaptive_layout.dart';

/// Bottom-nav shell for admin / finance / super-admin users.
/// On wide screens (≥ 900 px) this renders a premium left sidebar instead
/// of the mobile bottom navigation bar.
class AdminShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AdminShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ref.read(fcmServiceProvider).init();
      } catch (e) {
        debugPrint('FCM init ignored: $e');
      }
    });
  }

  static const _navItems = [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
    _NavItem(Icons.group_outlined, Icons.group_rounded, 'Members'),
    _NavItem(Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Reports'),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  void _onBranchSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mobileChild: _MobileShell(
        navigationShell: widget.navigationShell,
        navItems: _navItems,
        onBranchSelected: _onBranchSelected,
      ),
      desktopChild: _DesktopShell(
        navigationShell: widget.navigationShell,
        navItems: _navItems,
        onBranchSelected: _onBranchSelected,
      ),
    );
  }
}

// ── Mobile Shell (unchanged bottom nav) ─────────────────────────────────────

class _MobileShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<_NavItem> navItems;
  final void Function(int) onBranchSelected;

  const _MobileShell({
    required this.navigationShell,
    required this.navItems,
    required this.onBranchSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        height: 68,
        elevation: 0,
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: onBranchSelected,
        destinations: navItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Desktop Shell (sidebar) ───────────────────────────────────────────────────

class _DesktopShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  final List<_NavItem> navItems;
  final void Function(int) onBranchSelected;

  const _DesktopShell({
    required this.navigationShell,
    required this.navItems,
    required this.onBranchSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          // ── Left Sidebar ───────────────────────────────────────────────────
          _Sidebar(
            currentIndex: navigationShell.currentIndex,
            navItems: navItems,
            onBranchSelected: onBranchSelected,
            profile: profileAsync,
            theme: theme,
            ref: ref,
          ),

          // ── Main Content ───────────────────────────────────────────────────
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

// ── Sidebar Widget ───────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> navItems;
  final void Function(int) onBranchSelected;
  final AsyncValue<dynamic> profile;
  final ThemeData theme;
  final WidgetRef ref;

  const _Sidebar({
    required this.currentIndex,
    required this.navItems,
    required this.onBranchSelected,
    required this.profile,
    required this.theme,
    required this.ref,
  });

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.map((w) => w[0]).take(2).join().toUpperCase();
  }

  String _firstName(String? name) {
    if (name == null || name.trim().isEmpty) return 'User';
    final parts =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.first : 'User';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

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

          // ── Brand Logo + Name ──────────────────────────────────────────────
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

          const SizedBox(height: 20),

          // ── User Badge ────────────────────────────────────────────────────
          profile.whenOrNull(
            data: (p) {
              if (p == null) return const SizedBox.shrink();
              final roleLabel = _roleLabelFor(p.role);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.goldLight.withValues(
                          alpha: 0.25,
                        ),
                        child: Text(
                          _initials(p.fullName ?? ''),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _firstName(p.fullName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              roleLabel,
                              style: TextStyle(
                                color: AppColors.goldBright.withValues(
                                  alpha: 0.85,
                                ),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ) ?? const SizedBox.shrink(),

          const SizedBox(height: 28),

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
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = currentIndex == index;
                return _SidebarNavTile(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => onBranchSelected(index),
                );
              },
            ),
          ),

          // ── Sign Out ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
            child: _SidebarSignOutTile(ref: ref),
          ),
        ],
      ),
    );
  }

  String _roleLabelFor(UserRole? role) {
    return switch (role) {
      UserRole.SUPER_ADMIN => 'Super Admin',
      UserRole.FINANCE_OFFICER => 'Finance Officer',
      UserRole.ADMIN => 'Admin',
      _ => 'Admin',
    };
  }
}

// ── Sidebar Nav Tile ─────────────────────────────────────────────────────────

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              // Active indicator bar
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
                    : Colors.white.withValues(alpha: _hovered ? 0.9 : 0.65),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                widget.item.label,
                style: TextStyle(
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: _hovered ? 0.9 : 0.65),
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

// ── Sidebar Sign Out Tile ─────────────────────────────────────────────────────

class _SidebarSignOutTile extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _SidebarSignOutTile({required this.ref});

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
        onTap: () => ref.read(authControllerProvider.notifier).signOut(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                color: Colors.white.withValues(alpha: _hovered ? 0.9 : 0.5),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: _hovered ? 0.9 : 0.55),
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
