import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/pledge.dart';

class PledgeRepository {
  final FirebaseFirestore _firestore;

  PledgeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _pledges =>
      _firestore.collection('pledges');

  /// Stream all pledges for a specific user.
  Stream<List<Pledge>> watchUserPledges(String userId) {
    return _pledges
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final pledges = snapshot.docs
          .map((doc) => Pledge.fromMap(doc.data(), doc.id))
          .toList();
      // Sort in memory to avoid requiring a composite index
      pledges.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return pledges;
    });
  }

  /// Stream a user's pledge for a specific campaign.
  Stream<Pledge?> watchUserPledgeForCampaign(String userId, String campaignId) {
    return _pledges
        .where('userId', isEqualTo: userId)
        .where('campaignId', isEqualTo: campaignId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return Pledge.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
    });
  }

  /// Create a new pledge.
  /// (amountPaid is initially 0, and status is computed to PLEDGED automatically)
  Future<void> createPledge({
    required String campaignId,
    required String userId,
    required double pledgedAmount,
  }) async {
    final now = DateTime.now();
    
    // Check if pledge already exists
    final existing = await _pledges
        .where('userId', isEqualTo: userId)
        .where('campaignId', isEqualTo: campaignId)
        .get();
        
    if (existing.docs.isNotEmpty) {
      throw Exception('You have already made a pledge for this campaign. You can update it instead.');
    }

    final pledge = Pledge(
      id: '', // Handled by Firestore
      campaignId: campaignId,
      userId: userId,
      pledgedAmount: pledgedAmount,
      amountPaid: 0.0,
      status: PledgeStatus.PLEDGED,
      createdAt: now,
      updatedAt: now,
    );

    // Also update campaign statistics (transaction)
    // Note: In a real production app, this would be better handled by a Cloud Function trigger 
    // to ensure absolute data consistency, but we'll use a transaction here.
    await _firestore.runTransaction((transaction) async {
      final campaignRef = _firestore.collection('campaigns').doc(campaignId);
      final campaignDoc = await transaction.get(campaignRef);
      
      if (!campaignDoc.exists) {
        throw Exception('Campaign does not exist');
      }
      
      // Add pledge document
      final newPledgeRef = _pledges.doc();
      transaction.set(newPledgeRef, pledge.toMap());
      
      // Update campaign stats
      final currentPledged = (campaignDoc.data()?['totalPledged'] as num?)?.toDouble() ?? 0.0;
      final currentParticipants = (campaignDoc.data()?['participantsCount'] as num?)?.toInt() ?? 0;
      
      transaction.update(campaignRef, {
        'totalPledged': currentPledged + pledgedAmount,
        'participantsCount': currentParticipants + 1,
      });
    });
  }
}
