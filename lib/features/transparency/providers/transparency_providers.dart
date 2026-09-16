import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/transparency_repository.dart';
import '../domain/models/visibility_settings.dart';
import '../domain/models/public_contributor.dart';

final transparencyRepositoryProvider = Provider<TransparencyRepository>((ref) {
  return TransparencyRepository();
});

final visibilitySettingsProvider = StreamProvider<VisibilitySettings>((ref) {
  return ref.read(transparencyRepositoryProvider).watchVisibilitySettings();
});

final syncContributorsProvider =
    FutureProvider.family<void, VisibilitySettings>((ref, settings) async {
      await ref
          .read(transparencyRepositoryProvider)
          .syncAllContributors(settings);
    });

// A provider for saving settings
class VisibilitySettingsNotifier extends AsyncNotifier<void> {
  late TransparencyRepository _repo;

  @override
  FutureOr<void> build() {
    _repo = ref.watch(transparencyRepositoryProvider);
  }

  Future<void> updateSettings(VisibilitySettings settings) async {
    state = const AsyncLoading();
    try {
      await _repo.updateVisibilitySettings(settings);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final visibilitySettingsControllerProvider =
    AsyncNotifierProvider<VisibilitySettingsNotifier, void>(
      VisibilitySettingsNotifier.new,
    );

// Controller for paginated list
class ContributorsController extends AsyncNotifier<List<PublicContributor>> {
  String _campaignId = '';
  String? _statusFilter;
  String? _searchQuery;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  @override
  FutureOr<List<PublicContributor>> build() {
    return const [];
  }

  Future<void> loadInitial({
    required String campaignId,
    String? statusFilter,
    String? searchQuery,
  }) async {
    _campaignId = campaignId;
    _statusFilter = statusFilter;
    _searchQuery = searchQuery;
    _lastDoc = null;
    _hasMore = true;

    state = const AsyncLoading();
    try {
      var q = FirebaseFirestore.instance
          .collection('public_contributors')
          .where('campaignId', isEqualTo: _campaignId);

      if (_statusFilter != null &&
          _statusFilter!.isNotEmpty &&
          _statusFilter != 'ALL') {
        q = q.where('status', isEqualTo: _statusFilter);
      }

      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        final searchLower = _searchQuery!.toLowerCase();
        q = q
            .where('searchableName', isGreaterThanOrEqualTo: searchLower)
            .where('searchableName', isLessThan: '$searchLower\uf8ff');
      } else {
        q = q.orderBy('searchableName');
      }

      q = q.limit(20);
      final snapshot = await q.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDoc = snapshot.docs.last;
        if (snapshot.docs.length < 20) _hasMore = false;
      } else {
        _hasMore = false;
      }

      final list = snapshot.docs
          .map((doc) => PublicContributor.fromMap(doc.data(), doc.id))
          .toList();
      state = AsyncData(list);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;

    try {
      var q = FirebaseFirestore.instance
          .collection('public_contributors')
          .where('campaignId', isEqualTo: _campaignId);

      if (_statusFilter != null &&
          _statusFilter!.isNotEmpty &&
          _statusFilter != 'ALL') {
        q = q.where('status', isEqualTo: _statusFilter);
      }

      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        final searchLower = _searchQuery!.toLowerCase();
        q = q
            .where('searchableName', isGreaterThanOrEqualTo: searchLower)
            .where('searchableName', isLessThan: '$searchLower\uf8ff');
      } else {
        q = q.orderBy('searchableName');
      }

      if (_lastDoc != null) {
        q = q.startAfterDocument(_lastDoc!);
      }

      q = q.limit(20);
      final snapshot = await q.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDoc = snapshot.docs.last;
        if (snapshot.docs.length < 20) _hasMore = false;

        final newList = snapshot.docs
            .map((doc) => PublicContributor.fromMap(doc.data(), doc.id))
            .toList();
        state = AsyncData([...state.value ?? [], ...newList]);
      } else {
        _hasMore = false;
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final contributorsControllerProvider =
    AsyncNotifierProvider<ContributorsController, List<PublicContributor>>(
      ContributorsController.new,
    );
