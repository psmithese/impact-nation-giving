import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../auth/domain/models/app_user.dart';
import '../../../campaigns/providers/campaign_providers.dart';
import '../../../members/providers/member_providers.dart';
import '../../domain/models/pledge.dart';
import '../../providers/pledge_providers.dart';

class AdminPledgesScreen extends ConsumerWidget {
  const AdminPledgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pledgesAsync = ref.watch(allPledgesForCampaignProvider);
    final campaignAsync = ref.watch(activeCampaignProvider);
    final profileAsync = ref.watch(myProfileProvider);
    final theme = Theme.of(context);

    final isSuperAdmin =
        profileAsync.value?.role == UserRole.SUPER_ADMIN;

    final campaignName = campaignAsync.value?.name ?? 'Active Campaign';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pledges'),
            Text(
              campaignName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        actions: [
          pledgesAsync.whenOrNull(
            data: (list) => Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${list.length} pledge${list.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: pledgesAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (pledges) {
          if (pledges.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.handshake_outlined,
                    size: 80,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pledges yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pledges for the active campaign\nwill appear here.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pledges.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _PledgeAdminCard(
              pledge: pledges[index],
              isSuperAdmin: isSuperAdmin,
            ),
          );
        },
      ),
    );
  }
}

// ── Pledge admin card ─────────────────────────────────────────────────────────

class _PledgeAdminCard extends ConsumerWidget {
  final Pledge pledge;
  final bool isSuperAdmin;

  const _PledgeAdminCard({
    required this.pledge,
    required this.isSuperAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy');
    final status = pledge.computedStatus;
    final deleteState = ref.watch(deletePledgeControllerProvider);

    final (statusColor, statusLabel) = switch (status) {
      PledgeStatus.FULLY_PAID => (AppColors.success, 'Fully Paid'),
      PledgeStatus.PARTIAL_PAYMENT => (Colors.orange, 'Partial'),
      PledgeStatus.PLEDGED => (Colors.blue, 'Pledged'),
      PledgeStatus.CANCELLED => (AppColors.error, 'Cancelled'),
      PledgeStatus.NO_PLEDGE => (Colors.grey, 'No Pledge'),
    };

    final progress = pledge.pledgedAmount > 0
        ? (pledge.amountPaid / pledge.pledgedAmount).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ────────────────────────────────────────────
            Row(
              children: [
                // User ID / Avatar placeholder
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User: ${pledge.userId.substring(0, pledge.userId.length.clamp(0, 8))}…',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      Text(
                        'Pledged: ${dateFormat.format(pledge.createdAt)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Delete button — super admin only
                if (isSuperAdmin) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Delete Pledge',
                    icon: deleteState.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline_rounded,
                            color: AppColors.error, size: 20),
                    onPressed: deleteState.isLoading
                        ? null
                        : () => _confirmDelete(context, ref),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 14),

            // ── Progress bar ──────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor:
                    theme.colorScheme.surfaceContainerHighest,
                valueColor:
                    AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),

            const SizedBox(height: 14),

            // ── Amounts row ───────────────────────────────────────────
            Row(
              children: [
                _AmountBlock(
                  label: 'Pledged',
                  value: currency.format(pledge.pledgedAmount),
                  color: theme.colorScheme.onSurface,
                ),
                _divider(),
                _AmountBlock(
                  label: 'Paid',
                  value: currency.format(pledge.amountPaid),
                  color: statusColor,
                ),
                _divider(),
                _AmountBlock(
                  label: 'Balance',
                  value: currency.format(pledge.outstandingBalance),
                  color: pledge.outstandingBalance > 0
                      ? Colors.orange
                      : AppColors.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: Colors.grey.withValues(alpha: 0.2),
      );

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppColors.error, size: 22),
            const SizedBox(width: 8),
            const Text('Delete Pledge'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will permanently delete this pledge and automatically correct the campaign participant count and total pledged amount.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(deletePledgeControllerProvider.notifier)
          .deletePledge(pledge);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pledge deleted and counters corrected.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ── Amount block ──────────────────────────────────────────────────────────────

class _AmountBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AmountBlock({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
