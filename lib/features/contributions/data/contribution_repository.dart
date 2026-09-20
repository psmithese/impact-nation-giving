import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/contribution.dart';
import '../../receipts/domain/models/receipt.dart';

class ContributionRepository {
  final FirebaseFirestore _firestore;

  ContributionRepository({
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _contributions =>
      _firestore.collection('contributions');

  /// Fetch a single contribution by ID. Returns null if not found.
  Future<Contribution?> getContribution(String contributionId) async {
    final doc = await _contributions.doc(contributionId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Contribution.fromMap(doc.data()!, doc.id);
  }


  Future<void> submitContribution({
    required String campaignId,
    required String pledgeId,
    required String userId,
    required double amount,
    required PaymentMethod paymentMethod,
    required DateTime paymentDate,
    String? note,
    String? receivedBy,
    // Bank transfer fields
    String? bankName,
    String? transferReference,
    File? proofFile,
  }) async {
    String? proofUrl;

    // Convert proof to base64 string to store directly in Firestore
    if (proofFile != null && paymentMethod == PaymentMethod.BANK_TRANSFER) {
      final bytes = await proofFile.readAsBytes();
      final base64String = base64Encode(bytes);
      proofUrl = 'data:image/jpeg;base64,$base64String';
    }

    final now = DateTime.now();
    final contribution = Contribution(
      id: '',
      campaignId: campaignId,
      pledgeId: pledgeId,
      userId: userId,
      amount: amount,
      paymentMethod: paymentMethod,
      paymentDate: paymentDate,
      note: note,
      receivedBy: receivedBy,
      bankName: bankName,
      transferReference: transferReference,
      proofUrl: proofUrl,
      // Always starts as pending — never affects totals until verified
      status: ContributionStatus.PENDING_VERIFICATION,
      createdAt: now,
      updatedAt: now,
    );

    await _contributions.add(contribution.toMap());
  }

  // ── Admin: Verify a contribution (in a Firestore transaction) ────────────────

  Future<void> verifyContribution({
    required String contributionId,
    required String adminUid,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final contribRef = _contributions.doc(contributionId);
      final contribDoc = await transaction.get(contribRef);

      if (!contribDoc.exists) throw Exception('Contribution not found');

      final contribution = Contribution.fromMap(contribDoc.data()!, contributionId);

      if (contribution.status != ContributionStatus.PENDING_VERIFICATION) {
        throw Exception('Contribution has already been reviewed');
      }

      // Security: Admin cannot verify their own contribution
      if (contribution.userId == adminUid) {
        throw Exception('You cannot verify your own contribution');
      }

      final now = DateTime.now();

      // Update pledge: increment amountPaid and recompute status
      final pledgeRef = _firestore.collection('pledges').doc(contribution.pledgeId);
      final pledgeDoc = await transaction.get(pledgeRef);

      if (!pledgeDoc.exists) throw Exception('Associated pledge not found');

      final pledgeData = pledgeDoc.data()!;
      final currentPaid = (pledgeData['amountPaid'] as num?)?.toDouble() ?? 0.0;
      final pledgedAmount = (pledgeData['pledgedAmount'] as num?)?.toDouble() ?? 0.0;
      final newPaid = currentPaid + contribution.amount;

      // Compute new pledge status
      String newPledgeStatus;
      if (newPaid >= pledgedAmount) {
        newPledgeStatus = 'FULLY_PAID';
      } else if (newPaid > 0) {
        newPledgeStatus = 'PARTIAL_PAYMENT';
      } else {
        newPledgeStatus = 'PLEDGED';
      }

      // Update campaign: increment totalVerified
      final campaignRef =
          _firestore.collection('campaigns').doc(contribution.campaignId);
      final campaignDoc = await transaction.get(campaignRef);
      if (!campaignDoc.exists) throw Exception('Campaign not found');

      final currentVerified =
          (campaignDoc.data()?['totalVerified'] as num?)?.toDouble() ?? 0.0;
      final campaignName = campaignDoc.data()?['name'] as String? ?? 'Unknown Campaign';

      // Fetch user to get memberName
      final userRef = _firestore.collection('users').doc(contribution.userId);
      final userDoc = await transaction.get(userRef);
      final memberName = userDoc.data()?['fullName'] as String? ?? 'Unknown Member';

      // Generate Receipt
      final receiptId = 'RCPT-${const Uuid().v4().substring(0, 8).toUpperCase()}-${now.millisecondsSinceEpoch.toString().substring(8)}';
      
      final receipt = Receipt(
        id: receiptId,
        contributionId: contributionId,
        campaignName: campaignName,
        memberName: memberName,
        amount: contribution.amount,
        paymentMethod: contribution.paymentMethod.name,
        transferReference: contribution.transferReference,
        receivedBy: contribution.receivedBy,
        paymentDate: contribution.paymentDate,
        verifiedAt: now,
      );

      final receiptRef = _firestore.collection('receipts').doc(receiptId);

      // Apply all updates atomically
      transaction.set(receiptRef, receipt.toMap());

      transaction.update(contribRef, {
        'status': ContributionStatus.VERIFIED.name,
        'verifiedBy': adminUid,
        'verifiedAt': now.millisecondsSinceEpoch,
        'receiptId': receiptId,
        'updatedAt': now.millisecondsSinceEpoch,
      });

      transaction.update(pledgeRef, {
        'amountPaid': newPaid,
        'status': newPledgeStatus,
        'updatedAt': now.millisecondsSinceEpoch,
      });

      transaction.update(campaignRef, {
        'totalVerified': currentVerified + contribution.amount,
        'updatedAt': now.millisecondsSinceEpoch,
      });
    });
  }

  // ── Admin: Reject a contribution ─────────────────────────────────────────────

  Future<void> rejectContribution({
    required String contributionId,
    required String adminUid,
    required String reason,
  }) async {
    final contribRef = _contributions.doc(contributionId);
    final contribDoc = await contribRef.get();

    if (!contribDoc.exists) throw Exception('Contribution not found');

    final contribution = Contribution.fromMap(contribDoc.data()!, contributionId);

    if (contribution.status != ContributionStatus.PENDING_VERIFICATION) {
      throw Exception('Contribution has already been reviewed');
    }

    if (contribution.userId == adminUid) {
      throw Exception('You cannot reject your own contribution');
    }

    final now = DateTime.now();
    await contribRef.update({
      'status': ContributionStatus.REJECTED.name,
      'verifiedBy': adminUid,
      'verifiedAt': now.millisecondsSinceEpoch,
      'rejectionReason': reason,
      'updatedAt': now.millisecondsSinceEpoch,
    });
  }

  // ── Streams ──────────────────────────────────────────────────────────────────

  /// All contributions for a specific pledge (member view).
  /// If [userId] is provided, filters by userId as well to satisfy Firestore security rules.
  Stream<List<Contribution>> watchContributionsForPledge(
    String pledgeId, {
    String? userId,
  }) {
    Query<Map<String, dynamic>> query =
        _contributions.where('pledgeId', isEqualTo: pledgeId);
    if (userId != null && userId.isNotEmpty) {
      query = query.where('userId', isEqualTo: userId);
    }
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Contribution.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// All contributions by a specific user.
  Stream<List<Contribution>> watchUserContributions(String userId) {
    return _contributions
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Contribution.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// All pending contributions across the system (admin verification queue).
  Stream<List<Contribution>> watchPendingContributions() {
    return _contributions
        .where('status',
            isEqualTo: ContributionStatus.PENDING_VERIFICATION.name)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Contribution.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// All contributions for admin management.
  Stream<List<Contribution>> watchAllContributions() {
    return _contributions.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Contribution.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
