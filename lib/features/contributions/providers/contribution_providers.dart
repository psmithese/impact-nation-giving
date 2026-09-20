import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/models/app_user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/data/notification_repository.dart';
import '../../notifications/domain/models/app_notification.dart';
import '../../notifications/providers/notification_providers.dart';
import '../data/contribution_repository.dart';
import '../domain/models/contribution.dart';
import '../../security/data/audit_logger.dart';

final contributionRepositoryProvider = Provider<ContributionRepository>((ref) {
  return ContributionRepository();
});

/// All contributions submitted by the current logged-in user.
final myContributionsProvider = StreamProvider<List<Contribution>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(contributionRepositoryProvider).watchUserContributions(user.uid);
});

/// Contributions for a specific pledge.
final pledgeContributionsProvider =
    StreamProvider.family<List<Contribution>, String>((ref, pledgeId) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return const Stream.empty();
  final isMember = user.role == UserRole.MEMBER;
  return ref
      .watch(contributionRepositoryProvider)
      .watchContributionsForPledge(
        pledgeId,
        userId: isMember ? user.uid : null,
      );
});

/// Pending contributions awaiting admin verification.
final pendingContributionsProvider = StreamProvider<List<Contribution>>((ref) {
  return ref.watch(contributionRepositoryProvider).watchPendingContributions();
});

/// All contributions (admin view).
final allContributionsProvider = StreamProvider<List<Contribution>>((ref) {
  return ref.watch(contributionRepositoryProvider).watchAllContributions();
});

// ── Member Submission Controller ──────────────────────────────────────────────

class SubmitContributionController extends AsyncNotifier<void> {
  late ContributionRepository _repo;
  late NotificationRepository _notifRepo;

  @override
  Future<void> build() async {
    _repo = ref.watch(contributionRepositoryProvider);
    _notifRepo = ref.watch(notificationRepositoryProvider);
  }

  Future<void> submit({
    required String campaignId,
    required String pledgeId,
    required double amount,
    required PaymentMethod paymentMethod,
    required DateTime paymentDate,
    String? note,
    String? receivedBy,
    String? bankName,
    String? transferReference,
    File? proofFile,
  }) async {
    state = const AsyncLoading();

    final user = ref.read(authStateChangesProvider).value;
    if (user == null) {
      state = AsyncError(Exception('Not authenticated'), StackTrace.current);
      return;
    }

    try {
      await _repo.submitContribution(
        campaignId: campaignId,
        pledgeId: pledgeId,
        userId: user.uid,
        amount: amount,
        paymentMethod: paymentMethod,
        paymentDate: paymentDate,
        note: note,
        receivedBy: receivedBy,
        bankName: bankName,
        transferReference: transferReference,
        proofFile: proofFile,
      );

      // Notify the member that their submission was received
      try {
        await _notifRepo.sendNotification(AppNotification(
          id: '',
          userId: user.uid,
          title: 'Payment Submitted',
          body: 'Your payment of ₦${amount.toStringAsFixed(0)} has been submitted and is awaiting verification.',
          type: NotificationType.PAYMENT_SUBMITTED,
          isRead: false,
          createdAt: DateTime.now(),
        ));
      } catch (notifErr) {
        // Notification failure should not block successful payment submission
      }

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final submitContributionProvider =
    AsyncNotifierProvider<SubmitContributionController, void>(
  SubmitContributionController.new,
);

// ── Admin Verification Controller ─────────────────────────────────────────────

class VerifyContributionController extends AsyncNotifier<void> {
  late ContributionRepository _repo;
  late NotificationRepository _notifRepo;

  @override
  Future<void> build() async {
    _repo = ref.watch(contributionRepositoryProvider);
    _notifRepo = ref.watch(notificationRepositoryProvider);
  }

  Future<void> verify(String contributionId) async {
    state = const AsyncLoading();
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) {
      state = AsyncError(Exception('Not authenticated'), StackTrace.current);
      return;
    }
    try {
      // Fetch contribution first to get userId for the notification
      final contrib = await _repo.getContribution(contributionId);
      await _repo.verifyContribution(
        contributionId: contributionId,
        adminUid: user.uid,
      );
      await AuditLogger.logAction(
        adminId: user.uid,
        action: 'VERIFY_CONTRIBUTION',
        targetId: contributionId,
        targetType: 'contribution',
      );

      // Notify the member their payment was verified
      if (contrib != null) {
        await _notifRepo.sendNotification(AppNotification(
          id: '',
          userId: contrib.userId,
          title: 'Payment Verified ✓',
          body: 'Your payment of ₦${contrib.amount.toStringAsFixed(0)} has been verified. Thank you!',
          type: NotificationType.PAYMENT_VERIFIED,
          isRead: false,
          createdAt: DateTime.now(),
        ));
      }

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> reject({
    required String contributionId,
    required String reason,
  }) async {
    state = const AsyncLoading();
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) {
      state = AsyncError(Exception('Not authenticated'), StackTrace.current);
      return;
    }
    try {
      // Fetch contribution first to get userId for the notification
      final contrib = await _repo.getContribution(contributionId);
      await _repo.rejectContribution(
        contributionId: contributionId,
        adminUid: user.uid,
        reason: reason,
      );
      await AuditLogger.logAction(
        adminId: user.uid,
        action: 'REJECT_CONTRIBUTION',
        targetId: contributionId,
        targetType: 'contribution',
        details: {'reason': reason},
      );

      // Notify the member their payment was rejected
      if (contrib != null) {
        await _notifRepo.sendNotification(AppNotification(
          id: '',
          userId: contrib.userId,
          title: 'Payment Rejected',
          body: 'Your payment could not be verified. Reason: $reason',
          type: NotificationType.PAYMENT_REJECTED,
          isRead: false,
          createdAt: DateTime.now(),
        ));
      }

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final verifyContributionProvider =
    AsyncNotifierProvider<VerifyContributionController, void>(
  VerifyContributionController.new,
);
