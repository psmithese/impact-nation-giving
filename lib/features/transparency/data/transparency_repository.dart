import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/visibility_settings.dart';
import '../domain/models/public_contributor.dart';

class TransparencyRepository {
  final FirebaseFirestore _firestore;

  TransparencyRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _settings =>
      _firestore.collection('settings');
  CollectionReference<Map<String, dynamic>> get _publicContributors =>
      _firestore.collection('public_contributors');

  // ── Settings ────────────────────────────────────────────────────────────────

  Stream<VisibilitySettings> watchVisibilitySettings() {
    return _settings.doc('visibility').snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return const VisibilitySettings();
      return VisibilitySettings.fromMap(doc.data()!);
    });
  }

  Future<VisibilitySettings> getVisibilitySettings() async {
    final doc = await _settings.doc('visibility').get();
    if (!doc.exists || doc.data() == null) return const VisibilitySettings();
    return VisibilitySettings.fromMap(doc.data()!);
  }

  Future<void> updateVisibilitySettings(VisibilitySettings settings) async {
    await _settings.doc('visibility').set(settings.toMap(), SetOptions(merge: true));
    // After updating settings, sync all contributors to enforce visibility instantly
    await syncAllContributors(settings);
  }

  // ── Sync Engine ─────────────────────────────────────────────────────────────

  /// Builds a `PublicContributor` object from raw data, masking fields based on settings.
  PublicContributor _buildPublicContributor({
    required String pledgeId,
    required String userId,
    required String campaignId,
    required Map<String, dynamic> userDoc,
    required Map<String, dynamic> pledgeDoc,
    List<Map<String, dynamic>>? payments,
    required VisibilitySettings settings,
  }) {
    final rawName = userDoc['fullName'] as String? ?? 'Unknown Member';
    
    // Sort payments by date descending if present
    List<PublicPayment>? history;
    DateTime? lastPaymentDate;
    if (payments != null && payments.isNotEmpty) {
      payments.sort((a, b) => (b['paymentDate'] as int).compareTo(a['paymentDate'] as int));
      history = payments.map((e) {
        return PublicPayment(
          amount: (e['amount'] as num).toDouble(),
          date: DateTime.fromMillisecondsSinceEpoch(e['paymentDate'] as int),
        );
      }).toList();
      lastPaymentDate = history.first.date;
    }

    return PublicContributor(
      id: pledgeId,
      userId: userId,
      campaignId: campaignId,
      searchableName: rawName.toLowerCase(),
      memberName: settings.showMemberName ? rawName : null,
      photoUrl: settings.showProfilePhoto ? userDoc['photoUrl'] as String? : null,
      department: settings.showDepartment ? userDoc['department'] as String? : null,
      pledgedAmount: settings.showPledgeAmount ? (pledgeDoc['pledgedAmount'] as num).toDouble() : null,
      amountPaid: settings.showAmountPaid ? (pledgeDoc['amountPaid'] as num).toDouble() : null,
      outstandingBalance: settings.showOutstandingBalance 
          ? ((pledgeDoc['pledgedAmount'] as num) - (pledgeDoc['amountPaid'] as num)).toDouble() 
          : null,
      status: settings.showPaymentStatus ? pledgeDoc['status'] as String? : null,
      lastPaymentDate: settings.showPaymentDate ? lastPaymentDate : null,
      paymentHistory: settings.showPaymentHistory ? history : null,
    );
  }

  /// Iterates over all pledges, masks fields according to the new settings,
  /// and updates the `public_contributors` collection.
  Future<void> syncAllContributors(VisibilitySettings settings) async {
    final pledgesSnapshot = await _firestore.collection('pledges').get();
    if (pledgesSnapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    
    for (final pledge in pledgesSnapshot.docs) {
      final pData = pledge.data();
      final userId = pData['userId'] as String;
      
      // Fetch user
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) continue;

      // Fetch verified contributions if history or date is needed
      List<Map<String, dynamic>>? payments;
      if (settings.showPaymentHistory || settings.showPaymentDate) {
        final contribs = await _firestore
            .collection('contributions')
            .where('pledgeId', isEqualTo: pledge.id)
            .where('status', isEqualTo: 'VERIFIED')
            .get();
        payments = contribs.docs.map((e) => e.data()).toList();
      }

      final pc = _buildPublicContributor(
        pledgeId: pledge.id,
        userId: userId,
        campaignId: pData['campaignId'] as String,
        userDoc: userDoc.data()!,
        pledgeDoc: pData,
        payments: payments,
        settings: settings,
      );

      final docRef = _publicContributors.doc(pledge.id);
      
      // By using set without merge, we completely replace the document. 
      // This enforces security because hidden fields are completely removed from Firestore.
      batch.set(docRef, pc.toMap());
    }

    await batch.commit();
  }

  // ── Member Retrieval ────────────────────────────────────────────────────────

  /// Fetches paginated list of public contributors with optional filters.
  Future<List<PublicContributor>> fetchContributors({
    required String campaignId,
    String? statusFilter,
    String? searchQuery,
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> query = _publicContributors
        .where('campaignId', isEqualTo: campaignId);

    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'ALL') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchLower = searchQuery.toLowerCase();
      query = query
          .where('searchableName', isGreaterThanOrEqualTo: searchLower)
          .where('searchableName', isLessThan: '$searchLower\uf8ff');
    } else {
      // If not searching, order by searchableName for consistent pagination
      query = query.orderBy('searchableName');
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => PublicContributor.fromMap(doc.data(), doc.id))
        .toList();
  }
}
