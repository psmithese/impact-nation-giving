import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/domain/models/app_user.dart';
import '../domain/models/member_profile.dart';

/// Pagination state for member lists.
class MembersPage {
  final List<MemberProfile> members;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const MembersPage({
    required this.members,
    this.lastDocument,
    required this.hasMore,
  });
}

class MemberRepository {
  final FirebaseFirestore _firestore;

  static const int _pageSize = 20;

  MemberRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  // ─── Own Profile ───────────────────────────────────────────────────────────

  Stream<MemberProfile?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return MemberProfile.fromMap(doc.data()!, doc.id);
    });
  }

  Future<MemberProfile?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return MemberProfile.fromMap(doc.data()!, doc.id);
  }

  /// Members may only update their own name, phone, and photo.
  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String phoneNumber,
    String? photoUrl,
  }) async {
    await _users.doc(uid).update({
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ─── Admin: Member List with Pagination ────────────────────────────────────

  Future<MembersPage> fetchMembers({
    DocumentSnapshot? startAfter,
    UserStatus? statusFilter,
    UserRole? roleFilter,
    String? searchQuery,
  }) async {
    Query<Map<String, dynamic>> query = _users.orderBy('fullName');

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.name);
    }
    if (roleFilter != null) {
      query = query.where('role', isEqualTo: roleFilter.name);
    }
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(_pageSize);
    final snapshot = await query.get();

    var members = snapshot.docs
        .map((doc) => MemberProfile.fromMap(doc.data(), doc.id))
        .toList();

    // Client-side name search (Firestore lacks full-text).
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      members = members
          .where(
            (m) =>
                m.fullName.toLowerCase().contains(q) ||
                m.email.toLowerCase().contains(q),
          )
          .toList();
    }

    return MembersPage(
      members: members,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: snapshot.docs.length == _pageSize,
    );
  }

  // ─── Admin: Status Management ──────────────────────────────────────────────

  Future<void> suspendMember(String uid) async {
    await _users.doc(uid).update({
      'status': UserStatus.SUSPENDED.name,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> reactivateMember(String uid) async {
    await _users.doc(uid).update({
      'status': UserStatus.ACTIVE.name,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
