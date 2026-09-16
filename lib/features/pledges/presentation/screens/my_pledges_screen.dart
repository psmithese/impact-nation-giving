import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../providers/pledge_providers.dart';
import '../../domain/models/pledge.dart';

class MyPledgesScreen extends ConsumerWidget {
  const MyPledgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pledgesAsync = ref.watch(userPledgesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Pledges'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
                    Icons.account_balance_wallet_outlined,
                    size: 80,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pledges found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pledges.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _PledgeCard(pledge: pledges[index]);
            },
          );
        },
      ),
    );
  }
}

class _PledgeCard extends StatelessWidget {
  final Pledge pledge;

  const _PledgeCard({required this.pledge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = pledge.computedStatus;
    
    final currencyFormat = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    
    // Status visual mapping
    Color statusColor;
    String statusLabel;
    
    switch (status) {
      case PledgeStatus.NO_PLEDGE:
        statusColor = Colors.grey;
        statusLabel = 'No Pledge';
        break;
      case PledgeStatus.PLEDGED:
        statusColor = Colors.blue;
        statusLabel = 'Pledged';
        break;
      case PledgeStatus.PARTIAL_PAYMENT:
        statusColor = Colors.orange;
        statusLabel = 'Partial Payment';
        break;
      case PledgeStatus.FULLY_PAID:
        statusColor = AppColors.success;
        statusLabel = 'Fully Paid';
        break;
      case PledgeStatus.CANCELLED:
        statusColor = AppColors.error;
        statusLabel = 'Cancelled';
        break;
    }

    final progress = pledge.pledgedAmount > 0 
        ? (pledge.amountPaid / pledge.pledgedAmount).clamp(0.0, 1.0)
        : 0.0;

    return InkWell(
      onTap: () => context.push('/pledges/contributions', extra: pledge),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Church Rent Campaign',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 24),
              
              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _StatBlock(
                      label: 'Pledged',
                      value: currencyFormat.format(pledge.pledgedAmount),
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: _StatBlock(
                      label: 'Paid',
                      value: currencyFormat.format(pledge.amountPaid),
                      color: statusColor,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: _StatBlock(
                      label: 'Outstanding',
                      value: currencyFormat.format(pledge.outstandingBalance),
                      color: pledge.outstandingBalance > 0 ? Colors.orange : AppColors.success,
                    ),
                  ),
                ],
              ),
              
              // Action row
              if (status != PledgeStatus.FULLY_PAID && status != PledgeStatus.CANCELLED) ...[  
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/pledges/submit', extra: pledge),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Submit Payment'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Center(
                child: Text('Tap to view payment history',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.35))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBlock({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
