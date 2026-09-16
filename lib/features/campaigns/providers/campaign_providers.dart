import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../notifications/data/notification_repository.dart';
import '../../notifications/domain/models/app_notification.dart';
import '../../notifications/providers/notification_providers.dart';
import '../data/campaign_repository.dart';
import '../domain/models/campaign.dart';

final campaignRepositoryProvider = Provider<CampaignRepository>((ref) {
  return CampaignRepository();
});

final allCampaignsProvider = StreamProvider<List<Campaign>>((ref) {
  return ref.watch(campaignRepositoryProvider).watchAllCampaigns();
});

final activeCampaignProvider = StreamProvider<Campaign?>((ref) {
  return ref.watch(campaignRepositoryProvider).watchActiveCampaign();
});

class CampaignController extends AsyncNotifier<void> {
  late CampaignRepository _repo;
  late NotificationRepository _notifRepo;

  @override
  Future<void> build() async {
    _repo = ref.watch(campaignRepositoryProvider);
    _notifRepo = ref.watch(notificationRepositoryProvider);
  }

  Future<void> createCampaign({
    required String name,
    required String description,
    required double targetAmount,
    required DateTime startDate,
    required DateTime endDate,
    CampaignStatus status = CampaignStatus.DRAFT,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.createCampaign(
        name: name,
        description: description,
        targetAmount: targetAmount,
        startDate: startDate,
        endDate: endDate,
        status: status,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateCampaign(Campaign campaign) async {
    state = const AsyncLoading();
    try {
      await _repo.updateCampaign(campaign);

      // Check for milestone / completion notifications
      if (campaign.targetAmount > 0) {
        final pct = campaign.totalVerified / campaign.targetAmount;

        if (campaign.status == CampaignStatus.COMPLETED || pct >= 1.0) {
          await _notifRepo.sendNotification(AppNotification(
            id: '',
            userId: 'ALL',
            title: '🎉 Campaign Completed!',
            body: '"${campaign.name}" has reached its fundraising goal. Thank you to all contributors!',
            type: NotificationType.CAMPAIGN_COMPLETED,
            isRead: false,
            createdAt: DateTime.now(),
          ));
        } else if (pct >= 0.5) {
          await _notifRepo.sendNotification(AppNotification(
            id: '',
            userId: 'ALL',
            title: '🚀 Halfway There!',
            body: '"${campaign.name}" has reached 50% of its goal. Keep the momentum going!',
            type: NotificationType.CAMPAIGN_MILESTONE,
            isRead: false,
            createdAt: DateTime.now(),
          ));
        }
      }

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final campaignControllerProvider =
    AsyncNotifierProvider<CampaignController, void>(
  CampaignController.new,
);
