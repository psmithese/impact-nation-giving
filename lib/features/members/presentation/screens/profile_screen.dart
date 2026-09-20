import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_provider_util.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/domain/models/app_user.dart';
import '../../providers/member_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (profile) {
          if (profile == null) {
            return const ErrorState(message: 'Profile not found');
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myProfileProvider.future),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // ── Hero banner ─────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        _LargeAvatar(profile: profile),
                        const SizedBox(height: 12),
                        Text(
                          profile.fullName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _RoleChip(role: _roleLabel(profile.role)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Info section ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outline
                              .withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        children: [
                          _InfoTile(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: profile.email,
                          ),
                          const Divider(height: 1, indent: 56),
                          _InfoTile(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: profile.phoneNumber.isNotEmpty
                                ? profile.phoneNumber
                                : '—',
                          ),
                          const Divider(height: 1, indent: 56),
                          _InfoTile(
                            icon: Icons.shield_outlined,
                            label: 'Role',
                            value: _roleLabel(profile.role),
                          ),
                          const Divider(height: 1, indent: 56),
                          _InfoTile(
                            icon: Icons.circle_outlined,
                            label: 'Status',
                            value: _statusLabel(profile.status),
                          ),
                          const Divider(height: 1, indent: 56),
                          _InfoTile(
                            icon: Icons.calendar_today_outlined,
                            label: 'Member since',
                            value: _formatDate(profile.createdAt),
                          ),
                          const Divider(height: 1, indent: 56),
                          Consumer(
                            builder: (context, ref, child) {
                              final mode = ref.watch(themeModeProvider);
                              IconData icon;
                              String modeName;
                              if (mode == ThemeMode.light) {
                                icon = Icons.light_mode_outlined;
                                modeName = 'Light';
                              } else if (mode == ThemeMode.dark) {
                                icon = Icons.dark_mode_outlined;
                                modeName = 'Dark';
                              } else {
                                icon = Icons.brightness_auto_outlined;
                                modeName = 'System';
                              }
                              return ListTile(
                                leading: Icon(icon, color: theme.colorScheme.primary, size: 22),
                                title: Text('Theme', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                                subtitle: Text(modeName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  ref.read(themeModeProvider.notifier).toggleTheme();
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Profile'),
                        onPressed: () {
                          final path =
                              GoRouterState.of(context).uri.path;
                          final editPath = path.startsWith('/admin')
                              ? '/admin/profile/edit'
                              : '/profile/edit';
                          context.push(editPath, extra: profile);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _roleLabel(UserRole role) {
    return switch (role.name) {
      'SUPER_ADMIN' => 'Super Admin',
      'ADMIN' => 'Admin',
      'FINANCE_OFFICER' => 'Finance Officer',
      _ => 'Member',
    };
  }

  String _statusLabel(UserStatus status) {
    final name = status.name;
    return name[0] + name.substring(1).toLowerCase();
  }

  String _formatDate(DateTime dt) =>
      '${dt.day} ${_months[dt.month - 1]} ${dt.year}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _LargeAvatar extends StatelessWidget {
  final dynamic profile;
  const _LargeAvatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    final photoUrl = profile.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(radius: 48, backgroundImage: getImageProvider(photoUrl));
    }
    final name = profile.fullName as String;
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((w) => w[0]).take(2).join()
        : '?';
    return CircleAvatar(
      radius: 48,
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      child: Text(
        initials.toUpperCase(),
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary, size: 22),
      title: Text(label,
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
      subtitle: Text(value,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w500)),
    );
  }
}
