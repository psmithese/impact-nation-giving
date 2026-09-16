import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/data/notification_repository.dart';
import '../../notifications/domain/models/app_notification.dart';
import '../../notifications/providers/notification_providers.dart';
import '../data/pledge_repository.dart';
import '../domain/models/pledge.dart';

final pledgeRepositoryProvider = Provider<PledgeRepository>((ref) {
  return PledgeRepository();
});

/// Watches all pledges for the currently logged in user.
final userPledgesProvider = StreamProvider<List<Pledge>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return const Stream.empty();
  
  return ref.watch(pledgeRepositoryProvider).watchUserPledges(user.uid);
});

/// Watches a user's pledge for a specific campaign.
final userPledgeForCampaignProvider = StreamProvider.family<Pledge?, String>((ref, campaignId) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return const Stream.empty();
  
  return ref.watch(pledgeRepositoryProvider).watchUserPledgeForCampaign(user.uid, campaignId);
});

class PledgeController extends AsyncNotifier<void> {
  late PledgeRepository _repo;
  late NotificationRepository _notifRepo;

  @override
  Future<void> build() async {
    _repo = ref.watch(pledgeRepositoryProvider);
    _notifRepo = ref.watch(notificationRepositoryProvider);
  }

  Future<void> createPledge({
    required String campaignId,
    required double pledgedAmount,
  }) async {
    state = const AsyncLoading();
    
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) {
      state = AsyncError(Exception('User not logged in'), StackTrace.current);
      return;
    }
    
    try {
      await _repo.createPledge(
        campaignId: campaignId,
        userId: user.uid,
        pledgedAmount: pledgedAmount,
      );

      // Notify the member that their pledge was recorded
      await _notifRepo.sendNotification(AppNotification(
        id: '',
        userId: user.uid,
        title: 'Pledge Created',
        body: 'Your pledge of ₦${pledgedAmount.toStringAsFixed(0)} has been recorded. Thank you for your commitment!',
        type: NotificationType.PLEDGE_CREATED,
        isRead: false,
        createdAt: DateTime.now(),
      ));

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      // Re-throw to handle it in the UI (e.g., showing a SnackBar)
      rethrow; 
    }
  }
}

final pledgeControllerProvider = AsyncNotifierProvider<PledgeController, void>(
  PledgeController.new,
);
