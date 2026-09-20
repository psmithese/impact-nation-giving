import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../campaigns/providers/campaign_providers.dart';

class AdminDashboardStats {
  final int totalMembers;
  final int totalParticipants;
  final int fullyPaidMembers;
  final int partiallyPaidMembers;
  final int pledgedOnlyMembers;

  final double totalTarget;
  final double totalPledged;
  final double totalVerified;

  final List<Map<String, dynamic>> contributionsOverTime;
  final Map<String, double> paymentMethods;

  AdminDashboardStats({
    required this.totalMembers,
    required this.totalParticipants,
    required this.fullyPaidMembers,
    required this.partiallyPaidMembers,
    required this.pledgedOnlyMembers,
    required this.totalTarget,
    required this.totalPledged,
    required this.totalVerified,
    required this.contributionsOverTime,
    required this.paymentMethods,
  });
}

final adminDashboardStatsProvider = FutureProvider.autoDispose<AdminDashboardStats>((
  ref,
) async {
  final activeCampaign = ref.watch(activeCampaignProvider).value;
  if (activeCampaign == null) {
    // No active campaign — return zeroed-out stats instead of crashing
    return AdminDashboardStats(
      totalMembers: 0,
      totalParticipants: 0,
      fullyPaidMembers: 0,
      partiallyPaidMembers: 0,
      pledgedOnlyMembers: 0,
      totalTarget: 0,
      totalPledged: 0,
      totalVerified: 0,
      contributionsOverTime: [],
      paymentMethods: {},
    );
  }

  final firestore = FirebaseFirestore.instance;

  // Total members
  final usersSnapshot = await firestore.collection('users').count().get();
  final totalMembers = usersSnapshot.count ?? 0;

  // Pledges for active campaign
  final pledgesSnapshot = await firestore
      .collection('pledges')
      .where('campaignId', isEqualTo: activeCampaign.id)
      .get();

  int totalParticipants = pledgesSnapshot.docs.length;
  int fullyPaid = 0;
  int partiallyPaid = 0;
  int pledgedOnly = 0;

  for (final doc in pledgesSnapshot.docs) {
    final status = doc.data()['status'] as String?;
    if (status == 'FULLY_PAID') {
      fullyPaid++;
    } else if (status == 'PARTIAL_PAYMENT') {
      partiallyPaid++;
    } else if (status == 'PLEDGED') {
      pledgedOnly++;
    }
  }

  // Contributions for charts
  // Note: no .orderBy() here — it would require a composite Firestore index.
  // We sort in-memory below after grouping by date.
  final contribsSnapshot = await firestore
      .collection('contributions')
      .where('campaignId', isEqualTo: activeCampaign.id)
      .where('status', isEqualTo: 'VERIFIED')
      .get();

  final Map<String, double> methods = {};
  final List<Map<String, dynamic>> overTime = [];

  for (final doc in contribsSnapshot.docs) {
    final data = doc.data();
    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final method = data['paymentMethod'] as String? ?? 'UNKNOWN';
    final rawDate = data['paymentDate'];
    final DateTime date = rawDate is Timestamp
        ? rawDate.toDate()
        : rawDate is int
        ? DateTime.fromMillisecondsSinceEpoch(rawDate)
        : DateTime.tryParse(rawDate?.toString() ?? '') ?? DateTime.now();

    methods[method] = (methods[method] ?? 0) + amount;

    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    overTime.add({'date': dateStr, 'amount': amount});
  }

  final Map<String, double> groupedOverTime = {};
  for (final item in overTime) {
    final d = item['date'] as String;
    final a = item['amount'] as double;
    groupedOverTime[d] = (groupedOverTime[d] ?? 0) + a;
  }

  final sortedGroupedOverTime =
      groupedOverTime.entries
          .map((e) => {'date': e.key, 'amount': e.value})
          .toList()
        ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

  return AdminDashboardStats(
    totalMembers: totalMembers,
    totalParticipants: totalParticipants,
    fullyPaidMembers: fullyPaid,
    partiallyPaidMembers: partiallyPaid,
    pledgedOnlyMembers: pledgedOnly,
    totalTarget: activeCampaign.targetAmount,
    totalPledged: activeCampaign.totalPledged,
    totalVerified: activeCampaign.totalVerified,
    contributionsOverTime: sortedGroupedOverTime,
    paymentMethods: methods,
  );
});
