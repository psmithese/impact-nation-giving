import 'package:cloud_firestore/cloud_firestore.dart';
import '../../campaigns/domain/models/campaign.dart';
import '../../pledges/domain/models/pledge.dart';
import '../../contributions/domain/models/contribution.dart';
import '../../members/domain/models/member_profile.dart';

class CampaignReportData {
  final Campaign campaign;
  final int fullyPaid;
  final int partial;
  final int pledgedOnly;
  final double outstanding;

  CampaignReportData({
    required this.campaign,
    required this.fullyPaid,
    required this.partial,
    required this.pledgedOnly,
    required this.outstanding,
  });
}

class MemberReportData {
  final MemberProfile member;
  final Pledge pledge;

  MemberReportData({
    required this.member,
    required this.pledge,
  });
}

class PaymentReportData {
  final Contribution contribution;
  final MemberProfile? member;

  PaymentReportData({
    required this.contribution,
    this.member,
  });
}

class ReportRepository {
  final FirebaseFirestore _firestore;
  static const int _pageSize = 20;

  ReportRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // --- Campaign Report ---
  Future<List<CampaignReportData>> getCampaignReports() async {
    final campaignsSnap = await _firestore.collection('campaigns').orderBy('createdAt', descending: true).get();
    
    List<CampaignReportData> reports = [];
    
    for (var doc in campaignsSnap.docs) {
      final campaign = Campaign.fromMap(doc.data(), doc.id);
      
      final fullyPaidSnap = await _firestore.collection('pledges')
          .where('campaignId', isEqualTo: campaign.id)
          .where('status', isEqualTo: PledgeStatus.FULLY_PAID.name)
          .count().get();
          
      final partialSnap = await _firestore.collection('pledges')
          .where('campaignId', isEqualTo: campaign.id)
          .where('status', isEqualTo: PledgeStatus.PARTIAL_PAYMENT.name)
          .count().get();
          
      final pledgedSnap = await _firestore.collection('pledges')
          .where('campaignId', isEqualTo: campaign.id)
          .where('status', isEqualTo: PledgeStatus.PLEDGED.name)
          .count().get();
          
      final outstanding = (campaign.totalPledged - campaign.totalVerified).clamp(0.0, double.infinity);
      
      reports.add(CampaignReportData(
        campaign: campaign,
        fullyPaid: fullyPaidSnap.count ?? 0,
        partial: partialSnap.count ?? 0,
        pledgedOnly: pledgedSnap.count ?? 0,
        outstanding: outstanding,
      ));
    }
    
    return reports;
  }

  // --- Member Report (Pledges) ---
  Future<Map<String, dynamic>> getMemberReports({
    DocumentSnapshot? startAfter,
    String? statusFilter,
    String? campaignId,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection('pledges').orderBy('createdAt', descending: true);

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('status', isEqualTo: statusFilter);
    }
    if (campaignId != null && campaignId.isNotEmpty) {
      query = query.where('campaignId', isEqualTo: campaignId);
    }
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(_pageSize);
    final snapshot = await query.get();
    
    List<MemberReportData> data = [];
    for (var doc in snapshot.docs) {
      final pledge = Pledge.fromMap(doc.data(), doc.id);
      final userDoc = await _firestore.collection('users').doc(pledge.userId).get();
      if (userDoc.exists) {
        data.add(MemberReportData(
          member: MemberProfile.fromMap(userDoc.data()!, userDoc.id),
          pledge: pledge,
        ));
      }
    }

    return {
      'data': data,
      'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      'hasMore': snapshot.docs.length == _pageSize,
    };
  }

  // --- Payment Report (Contributions) ---
  Future<Map<String, dynamic>> getPaymentReports({
    DocumentSnapshot? startAfter,
    String? statusFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection('contributions').orderBy('createdAt', descending: true);

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('status', isEqualTo: statusFilter);
    }
    
    // In Firestore, if we filter by a range (createdAt), we MUST order by the same field first, which we are doing above.
    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch);
    }
    if (endDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(_pageSize);
    final snapshot = await query.get();

    List<PaymentReportData> data = [];
    for (var doc in snapshot.docs) {
      final contribution = Contribution.fromMap(doc.data(), doc.id);
      final userDoc = await _firestore.collection('users').doc(contribution.userId).get();
      MemberProfile? member;
      if (userDoc.exists) {
        member = MemberProfile.fromMap(userDoc.data()!, userDoc.id);
      }
      data.add(PaymentReportData(
        contribution: contribution,
        member: member,
      ));
    }

    return {
      'data': data,
      'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      'hasMore': snapshot.docs.length == _pageSize,
    };
  }
}
