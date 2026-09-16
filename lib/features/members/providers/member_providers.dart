import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/models/app_user.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/member_repository.dart';
import '../domain/models/member_profile.dart';

// ─── Repository provider ───────────────────────────────────────────────────

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository();
});

// ─── Own profile stream ────────────────────────────────────────────────────

final myProfileProvider = StreamProvider<MemberProfile?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final uid = authState.value?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(memberRepositoryProvider).watchProfile(uid);
});

// ─── Edit Profile Controller ───────────────────────────────────────────────

class EditProfileController extends AsyncNotifier<void> {
  late MemberRepository _repo;

  @override
  Future<void> build() async {
    _repo = ref.watch(memberRepositoryProvider);
  }

  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String phoneNumber,
    String? photoUrl,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.updateProfile(
        uid: uid,
        fullName: fullName,
        phoneNumber: phoneNumber,
        photoUrl: photoUrl,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final editProfileControllerProvider =
    AsyncNotifierProvider<EditProfileController, void>(
  EditProfileController.new,
);

// ─── Admin: paginated member list ──────────────────────────────────────────

class MembersFilter {
  final UserStatus? statusFilter;
  final UserRole? roleFilter;
  final String searchQuery;

  const MembersFilter({
    this.statusFilter,
    this.roleFilter,
    this.searchQuery = '',
  });

  MembersFilter copyWith({
    UserStatus? statusFilter,
    bool clearStatus = false,
    UserRole? roleFilter,
    bool clearRole = false,
    String? searchQuery,
  }) {
    return MembersFilter(
      statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
      roleFilter: clearRole ? null : (roleFilter ?? this.roleFilter),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class MembersFilterNotifier extends Notifier<MembersFilter> {
  @override
  MembersFilter build() => const MembersFilter();

  void update(MembersFilter Function(MembersFilter) updater) {
    state = updater(state);
  }
}

final membersFilterProvider =
    NotifierProvider<MembersFilterNotifier, MembersFilter>(
  MembersFilterNotifier.new,
);

class MembersNotifier extends AsyncNotifier<List<MemberProfile>> {
  late MemberRepository _repo;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  Future<List<MemberProfile>> build() async {
    _repo = ref.watch(memberRepositoryProvider);
    // Re-fetch when filter changes.
    ref.watch(membersFilterProvider);
    _lastDoc = null;
    _hasMore = true;
    return _loadPage(refresh: true);
  }

  Future<List<MemberProfile>> _loadPage({bool refresh = false}) async {
    final filter = ref.read(membersFilterProvider);
    final page = await _repo.fetchMembers(
      startAfter: refresh ? null : _lastDoc,
      statusFilter: filter.statusFilter,
      roleFilter: filter.roleFilter,
      searchQuery: filter.searchQuery,
    );
    _lastDoc = page.lastDocument;
    _hasMore = page.hasMore;
    return page.members;
  }

  bool get hasMore => _hasMore;

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    try {
      final current = state.value ?? [];
      final more = await _loadPage();
      state = AsyncData([...current, ...more]);
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    _lastDoc = null;
    _hasMore = true;
    try {
      state = AsyncData(await _loadPage(refresh: true));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final membersNotifierProvider =
    AsyncNotifierProvider<MembersNotifier, List<MemberProfile>>(
  MembersNotifier.new,
);

// ─── Admin: member status controller ──────────────────────────────────────

class MemberStatusController extends AsyncNotifier<void> {
  late MemberRepository _repo;

  @override
  Future<void> build() async {
    _repo = ref.watch(memberRepositoryProvider);
  }

  Future<void> suspend(String uid) async {
    state = const AsyncLoading();
    try {
      await _repo.suspendMember(uid);
      state = const AsyncData(null);
      ref.invalidate(membersNotifierProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> reactivate(String uid) async {
    state = const AsyncLoading();
    try {
      await _repo.reactivateMember(uid);
      state = const AsyncData(null);
      ref.invalidate(membersNotifierProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final memberStatusControllerProvider =
    AsyncNotifierProvider<MemberStatusController, void>(
  MemberStatusController.new,
);

// ─── Single member profile ─────────────────────────────────────────────────

final memberProfileProvider =
    FutureProvider.family<MemberProfile?, String>((ref, uid) async {
  return ref.watch(memberRepositoryProvider).getProfile(uid);
});
