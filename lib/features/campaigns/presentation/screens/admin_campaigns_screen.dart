import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../providers/campaign_providers.dart';
import '../../domain/models/campaign.dart';

class AdminCampaignsScreen extends ConsumerWidget {
  const AdminCampaignsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(allCampaignsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Campaigns'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: campaignsAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (campaigns) {
          if (campaigns.isEmpty) {
            return const Center(child: Text('No campaigns found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              final campaign = campaigns[index];
              return _CampaignListTile(campaign: campaign);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/dashboard/campaigns/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Campaign'),
      ),
    );
  }
}

class _CampaignListTile extends StatelessWidget {
  final Campaign campaign;

  const _CampaignListTile({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color statusColor;
    switch (campaign.status) {
      case CampaignStatus.ACTIVE:
        statusColor = AppColors.success;
        break;
      case CampaignStatus.DRAFT:
        statusColor = Colors.grey;
        break;
      case CampaignStatus.PAUSED:
        statusColor = Colors.orange;
        break;
      case CampaignStatus.COMPLETED:
        statusColor = AppColors.primary;
        break;
      case CampaignStatus.ARCHIVED:
        statusColor = Colors.blueGrey;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(Icons.campaign, color: statusColor),
        ),
        title: Text(
          campaign.name,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Target: ₦${campaign.targetAmount.toStringAsFixed(0)}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                campaign.status.name,
                style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Go to edit screen
          context.push('/admin/dashboard/campaigns/edit', extra: campaign);
        },
      ),
    );
  }
}
