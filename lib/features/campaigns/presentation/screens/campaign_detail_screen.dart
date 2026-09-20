import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../providers/campaign_providers.dart';
import '../../domain/models/campaign.dart';

class CampaignDetailScreen extends ConsumerWidget {
  final String? campaignId;

  const CampaignDetailScreen({super.key, this.campaignId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If no ID provided, watch the active campaign. Otherwise, we'd watch a specific one.
    // For simplicity, we'll watch the active one if campaignId is null.
    final AsyncValue<Campaign?> campaignAsync;
    if (campaignId == null) {
      campaignAsync = ref.watch(activeCampaignProvider);
    } else {
      // If we had a fetch by ID provider:
      // campaignAsync = ref.watch(campaignByIdProvider(campaignId!));
      campaignAsync = ref.watch(activeCampaignProvider); // Fallback for now
    }

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Campaign Details'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: campaignAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (campaign) {
          if (campaign == null) {
            return const Center(child: Text('No active campaign found.'));
          }
          return _buildCampaignDetails(context, theme, campaign);
        },
      ),
      bottomNavigationBar: campaignAsync.whenOrNull(
        data: (campaign) => campaign != null && campaign.status == CampaignStatus.ACTIVE
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FilledButton(
                    onPressed: () {
                      context.push('/home/campaign/pledge', extra: campaign);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Make a Pledge'),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildCampaignDetails(
      BuildContext context, ThemeData theme, Campaign campaign) {
    final progress = campaign.progressPercentage;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Image / Gradient
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.church_rounded,
                size: 80,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatusChip(status: campaign.status),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}% Funded',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Text(
                  campaign.name,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  campaign.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Financial Stats
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Target Amount',
                        value: '₦${_formatCurrency(campaign.targetAmount)}',
                        icon: Icons.flag_rounded,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Verified',
                        value: '₦${_formatCurrency(campaign.totalVerified)}',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Pledged',
                        value: '₦${_formatCurrency(campaign.totalPledged)}',
                        icon: Icons.handshake_rounded,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Participants',
                        value: '${campaign.participantsCount}',
                        icon: Icons.group_rounded,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Dates
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              'Start Date',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(campaign.startDate),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 30, color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                        Column(
                          children: [
                            Text(
                              'End Date',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(campaign.endDate),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/home/campaign/contributors', extra: campaign),
                    icon: const Icon(Icons.people_alt_rounded),
                    label: const Text('View Contributors'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return CurrencyFormatter.formatCompact(amount);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _StatusChip extends StatelessWidget {
  final CampaignStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;

    switch (status) {
      case CampaignStatus.ACTIVE:
        color = AppColors.success;
        label = 'Active';
        break;
      case CampaignStatus.DRAFT:
        color = Colors.grey;
        label = 'Draft';
        break;
      case CampaignStatus.PAUSED:
        color = Colors.orange;
        label = 'Paused';
        break;
      case CampaignStatus.COMPLETED:
        color = AppColors.primary;
        label = 'Completed';
        break;
      case CampaignStatus.ARCHIVED:
        color = Colors.blueGrey;
        label = 'Archived';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
