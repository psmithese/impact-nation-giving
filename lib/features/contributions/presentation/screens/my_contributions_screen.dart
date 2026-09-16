import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../pledges/domain/models/pledge.dart';
import '../../domain/models/contribution.dart';
import '../../providers/contribution_providers.dart';

class MyContributionsScreen extends ConsumerWidget {
  final Pledge pledge;

  const MyContributionsScreen({super.key, required this.pledge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contribAsync =
        ref.watch(pledgeContributionsProvider(pledge.id));
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(symbol: '₦', decimalDigits: 0);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: contribAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (contributions) => CustomScrollView(
          slivers: [
            // Summary header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryRow(
                      label: 'Pledged',
                      value: currency.format(pledge.pledgedAmount),
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      label: 'Paid',
                      value: currency.format(pledge.amountPaid),
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      label: 'Outstanding',
                      value: currency.format(pledge.outstandingBalance),
                      color: pledge.outstandingBalance > 0
                          ? Colors.orange
                          : AppColors.success,
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: pledge.pledgedAmount > 0
                            ? (pledge.amountPaid / pledge.pledgedAmount)
                                .clamp(0.0, 1.0)
                            : 0.0,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.success),
                        minHeight: 10,
                      ),
                    ),
                    const Divider(height: 32),
                    Text('Payment History',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            if (contributions.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text('No payments submitted yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4))),
                ),
              )
            else
              SliverPadding(
                padding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.separated(
                  itemCount: contributions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _ContributionHistoryCard(
                        contribution: contributions[index]);
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton:
          pledge.computedStatus != PledgeStatus.FULLY_PAID &&
                  pledge.computedStatus != PledgeStatus.CANCELLED
              ? FloatingActionButton.extended(
                  onPressed: () =>
                      context.push('/pledges/submit', extra: pledge),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Submit Payment'),
                )
              : null,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        Text(value,
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _ContributionHistoryCard extends StatelessWidget {
  final Contribution contribution;

  const _ContributionHistoryCard({required this.contribution});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy');

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (contribution.status) {
      case ContributionStatus.PENDING_VERIFICATION:
        statusColor = Colors.orange;
        statusLabel = 'Pending';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case ContributionStatus.VERIFIED:
        statusColor = AppColors.success;
        statusLabel = 'Verified';
        statusIcon = Icons.check_circle_rounded;
        break;
      case ContributionStatus.REJECTED:
        statusColor = AppColors.error;
        statusLabel = 'Rejected';
        statusIcon = Icons.cancel_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: statusColor.withValues(alpha: 0.2)),
        color: statusColor.withValues(alpha: 0.03),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const Spacer(),
              Text(currency.format(contribution.amount),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                contribution.paymentMethod == PaymentMethod.CASH
                    ? Icons.payments_rounded
                    : Icons.account_balance_rounded,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 6),
              Text(
                contribution.paymentMethod == PaymentMethod.CASH
                    ? 'Cash'
                    : 'Bank Transfer',
                style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
              const SizedBox(width: 16),
              Icon(Icons.calendar_today_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              const SizedBox(width: 6),
              Text(
                dateFormat.format(contribution.paymentDate),
                style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
          if (contribution.status == ContributionStatus.REJECTED &&
              contribution.rejectionReason != null) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reason: ${contribution.rejectionReason}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (contribution.status == ContributionStatus.VERIFIED &&
              contribution.receiptId != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/pledges/receipt/${contribution.receiptId}'),
                icon: const Icon(Icons.receipt_long_rounded, size: 16),
                label: const Text('View Receipt'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  side: BorderSide(color: AppColors.success.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
