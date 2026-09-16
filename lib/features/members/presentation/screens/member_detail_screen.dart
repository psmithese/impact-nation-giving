import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_provider_util.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../auth/domain/models/app_user.dart';
import '../../domain/models/member_profile.dart';
import '../../providers/member_providers.dart';

class MemberDetailScreen extends ConsumerWidget {
  final String uid;
  const MemberDetailScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(memberProfileProvider(uid));
    final statusState = ref.watch(memberStatusControllerProvider);
    final theme = Theme.of(context);

    ref.listen<AsyncValue<void>>(memberStatusControllerProvider, (_, state) {
      state.whenOrNull(
        data: (_) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member status updated'),
            backgroundColor: AppColors.success,
          ),
        ),
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Member Details')),
      body: profileAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (profile) {
          if (profile == null) {
            return const ErrorState(message: 'Member not found');
          }

          final isSuspended = profile.status == UserStatus.SUSPENDED;

          return SingleChildScrollView(
            child: Column(
              children: [
                // ── Hero ────────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Column(
                    children: [
                      _Avatar(profile: profile),
                      const SizedBox(height: 10),
                      Text(
                        profile.fullName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.email,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      _StatusChip(status: profile.status),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Details ──────────────────────────────────────────────
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
                        _DetailTile(
                            icon: Icons.badge_outlined,
                            label: 'UID',
                            value: profile.uid),
                        const Divider(height: 1, indent: 56),
                        _DetailTile(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: profile.phoneNumber.isNotEmpty
                                ? profile.phoneNumber
                                : '—'),
                        const Divider(height: 1, indent: 56),
                        _DetailTile(
                            icon: Icons.shield_outlined,
                            label: 'Role',
                            value: _roleLabel(profile.role)),
                        const Divider(height: 1, indent: 56),
                        _DetailTile(
                            icon: Icons.calendar_today_outlined,
                            label: 'Joined',
                            value: _fmtDate(profile.createdAt)),
                        const Divider(height: 1, indent: 56),
                        _DetailTile(
                            icon: Icons.update_outlined,
                            label: 'Last updated',
                            value: _fmtDate(profile.updatedAt)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Admin actions ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: isSuspended
                      ? SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            icon: statusState.isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : const Icon(Icons.check_circle_outline),
                            label: const Text('Reactivate Member'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.success,
                            ),
                            onPressed: statusState.isLoading
                                ? null
                                : () => ref
                                    .read(memberStatusControllerProvider
                                        .notifier)
                                    .reactivate(profile.uid),
                          ),
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: statusState.isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.block),
                            label: const Text('Suspend Member'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side:
                                  const BorderSide(color: AppColors.error),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: statusState.isLoading
                                ? null
                                : () => _confirmSuspend(context, ref, profile),
                          ),
                        ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmSuspend(
      BuildContext context, WidgetRef ref, MemberProfile profile) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend Member'),
        content: Text(
          'Are you sure you want to suspend ${profile.fullName}? '
          'They will lose access to the app until reactivated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(memberStatusControllerProvider.notifier)
                  .suspend(profile.uid);
            },
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  String _roleLabel(UserRole role) => switch (role) {
        UserRole.SUPER_ADMIN => 'Super Admin',
        UserRole.ADMIN => 'Admin',
        UserRole.FINANCE_OFFICER => 'Finance Officer',
        UserRole.MEMBER => 'Member',
      };

  String _fmtDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final MemberProfile profile;
  const _Avatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile.photoUrl != null && profile.photoUrl!.isNotEmpty) {
      return CircleAvatar(
          radius: 44,
          backgroundImage: getImageProvider(profile.photoUrl!));
    }
    final name = profile.fullName;
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((w) => w[0]).take(2).join()
        : '?';
    return CircleAvatar(
      radius: 44,
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      child: Text(
        initials.toUpperCase(),
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final UserStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      UserStatus.ACTIVE => ('Active', Colors.greenAccent),
      UserStatus.SUSPENDED => ('Suspended', Colors.redAccent),
      UserStatus.INACTIVE => ('Inactive', Colors.white54),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12)),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(label,
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
      subtitle: Text(value,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w500)),
    );
  }
}
