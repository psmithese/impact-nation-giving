import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository();
});

// --- Campaign Report ---
final campaignReportProvider = FutureProvider<List<CampaignReportData>>((ref) async {
  return ref.watch(reportRepositoryProvider).getCampaignReports();
});

// --- Member Report (Pledges) State ---
class MemberReportState {
  final List<MemberReportData> data;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;
  final String? statusFilter;
  final String? campaignId;

  MemberReportState({
    this.data = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastDoc,
    this.statusFilter,
    this.campaignId,
  });

  MemberReportState copyWith({
    List<MemberReportData>? data,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
    String? statusFilter,
    String? campaignId,
  }) {
    return MemberReportState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      lastDoc: lastDoc ?? this.lastDoc,
      statusFilter: statusFilter ?? this.statusFilter,
      campaignId: campaignId ?? this.campaignId,
    );
  }
}

class MemberReportNotifier extends Notifier<MemberReportState> {
  late final ReportRepository _repo;

  @override
  MemberReportState build() {
    _repo = ref.watch(reportRepositoryProvider);
    Future.microtask(() => loadData());
    return MemberReportState();
  }

  Future<void> loadData({bool refresh = false}) async {
    if (state.isLoading) return;
    if (!refresh && !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final res = await _repo.getMemberReports(
        startAfter: refresh ? null : state.lastDoc,
        statusFilter: state.statusFilter,
        campaignId: state.campaignId,
      );

      final newData = res['data'] as List<MemberReportData>;
      final lastDoc = res['lastDocument'] as DocumentSnapshot?;
      final hasMore = res['hasMore'] as bool;

      state = state.copyWith(
        data: refresh ? newData : [...state.data, ...newData],
        lastDoc: lastDoc,
        hasMore: hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setFilter({String? status, String? campaignId}) {
    state = state.copyWith(
      statusFilter: status,
      campaignId: campaignId,
    );
    loadData(refresh: true);
  }
}

final memberReportProvider =
    NotifierProvider<MemberReportNotifier, MemberReportState>(MemberReportNotifier.new);

// --- Payment Report (Contributions) State ---
class PaymentReportState {
  final List<PaymentReportData> data;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;
  final String? statusFilter;
  final DateTime? startDate;
  final DateTime? endDate;

  PaymentReportState({
    this.data = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastDoc,
    this.statusFilter,
    this.startDate,
    this.endDate,
  });

  PaymentReportState copyWith({
    List<PaymentReportData>? data,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
    String? statusFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return PaymentReportState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      lastDoc: lastDoc ?? this.lastDoc,
      statusFilter: statusFilter ?? this.statusFilter,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class PaymentReportNotifier extends Notifier<PaymentReportState> {
  late final ReportRepository _repo;

  @override
  PaymentReportState build() {
    _repo = ref.watch(reportRepositoryProvider);
    Future.microtask(() => loadData());
    return PaymentReportState();
  }

  Future<void> loadData({bool refresh = false}) async {
    if (state.isLoading) return;
    if (!refresh && !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final res = await _repo.getPaymentReports(
        startAfter: refresh ? null : state.lastDoc,
        statusFilter: state.statusFilter,
        startDate: state.startDate,
        endDate: state.endDate,
      );

      final newData = res['data'] as List<PaymentReportData>;
      final lastDoc = res['lastDocument'] as DocumentSnapshot?;
      final hasMore = res['hasMore'] as bool;

      state = state.copyWith(
        data: refresh ? newData : [...state.data, ...newData],
        lastDoc: lastDoc,
        hasMore: hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setFilter({String? status, DateTime? startDate, DateTime? endDate}) {
    state = state.copyWith(
      statusFilter: status,
      startDate: startDate,
      endDate: endDate,
    );
    loadData(refresh: true);
  }
}

final paymentReportProvider =
    NotifierProvider<PaymentReportNotifier, PaymentReportState>(PaymentReportNotifier.new);
