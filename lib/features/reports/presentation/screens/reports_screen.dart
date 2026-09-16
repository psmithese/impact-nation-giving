import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../providers/report_providers.dart';
import '../../data/report_repository.dart';
import '../../../pledges/domain/models/pledge.dart';
import '../../../contributions/domain/models/contribution.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.secondary,
          tabs: const [
            Tab(text: 'Campaigns'),
            Tab(text: 'Members'),
            Tab(text: 'Payments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CampaignReportTab(),
          _MemberReportTab(),
          _PaymentReportTab(),
        ],
      ),
    );
  }
}

Future<void> _exportAndShareCsv(String csvData, String fileName) async {
  final bytes = utf8.encode(csvData);
  final file = XFile.fromData(bytes, name: fileName, mimeType: 'text/csv');
  await Share.shareXFiles([file], text: 'Exported Report');
}

// ─── Campaign Report Tab ───────────────────────────────────────────────────────

class _CampaignReportTab extends ConsumerWidget {
  const _CampaignReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(campaignReportProvider);
    final theme = Theme.of(context);

    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (reports) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Export CSV'),
                    onPressed: () => _exportCampaigns(reports),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final data = reports[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data.campaign.name,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _InfoRow('Target', '₦${data.campaign.targetAmount.toStringAsFixed(0)}'),
                          _InfoRow('Pledged', '₦${data.campaign.totalPledged.toStringAsFixed(0)}'),
                          _InfoRow('Verified', '₦${data.campaign.totalVerified.toStringAsFixed(0)}'),
                          _InfoRow('Outstanding', '₦${data.outstanding.toStringAsFixed(0)}'),
                          const Divider(),
                          _InfoRow('Participants', '${data.campaign.participantsCount}'),
                          _InfoRow('Fully Paid', '${data.fullyPaid}'),
                          _InfoRow('Partial Paid', '${data.partial}'),
                          _InfoRow('Pledged Only', '${data.pledgedOnly}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportCampaigns(List<CampaignReportData> reports) async {
    final buffer = StringBuffer();
    buffer.writeln(
        'Campaign,Target,Pledged,Verified,Outstanding,Participants,Fully Paid,Partial Paid,Pledged Only');
    for (var r in reports) {
      buffer.writeln(
          '"${r.campaign.name}",${r.campaign.targetAmount},${r.campaign.totalPledged},${r.campaign.totalVerified},${r.outstanding},${r.campaign.participantsCount},${r.fullyPaid},${r.partial},${r.pledgedOnly}');
    }
    await _exportAndShareCsv(
        buffer.toString(), 'Campaign_Report_${DateTime.now().millisecondsSinceEpoch}.csv');
  }
}

// ─── Member Report Tab ─────────────────────────────────────────────────────────

class _MemberReportTab extends ConsumerStatefulWidget {
  const _MemberReportTab();

  @override
  ConsumerState<_MemberReportTab> createState() => _MemberReportTabState();
}

class _MemberReportTabState extends ConsumerState<_MemberReportTab> {
  final _scrollController = ScrollController();
  PledgeStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(memberReportProvider.notifier).loadData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memberReportProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<PledgeStatus>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Filter Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  initialValue: _selectedStatus,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Status')),
                    ...PledgeStatus.values.map(
                      (e) => DropdownMenuItem(value: e, child: Text(e.name)),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedStatus = val);
                    ref
                        .read(memberReportProvider.notifier)
                        .setFilter(status: val?.name);
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Export'),
                onPressed: () => _exportMembers(state.data),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.data.isEmpty && !state.isLoading
              ? const Center(child: Text('No records found.'))
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: state.data.length + (state.hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index >= state.data.length) {
                      return const Center(
                          child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    final item = state.data[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: ListTile(
                        title: Text(item.member.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Pledge: ₦${item.pledge.pledgedAmount.toStringAsFixed(0)}'),
                            Text('Verified Paid: ₦${item.pledge.amountPaid.toStringAsFixed(0)}'),
                            Text('Outstanding: ₦${item.pledge.outstandingBalance.toStringAsFixed(0)}'),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(item.pledge.computedStatus.name,
                              style: const TextStyle(fontSize: 10)),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _exportMembers(List<MemberReportData> data) async {
    final buffer = StringBuffer();
    buffer.writeln('Member,Email,Phone,Pledge,Verified Paid,Outstanding,Status');
    for (var r in data) {
      buffer.writeln(
          '"${r.member.fullName}","${r.member.email}","${r.member.phoneNumber}",${r.pledge.pledgedAmount},${r.pledge.amountPaid},${r.pledge.outstandingBalance},${r.pledge.computedStatus.name}');
    }
    await _exportAndShareCsv(
        buffer.toString(), 'Member_Report_${DateTime.now().millisecondsSinceEpoch}.csv');
  }
}

// ─── Payment Report Tab ────────────────────────────────────────────────────────

class _PaymentReportTab extends ConsumerStatefulWidget {
  const _PaymentReportTab();

  @override
  ConsumerState<_PaymentReportTab> createState() => _PaymentReportTabState();
}

class _PaymentReportTabState extends ConsumerState<_PaymentReportTab> {
  final _scrollController = ScrollController();
  ContributionStatus? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(paymentReportProvider.notifier).loadData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
      });
      ref.read(paymentReportProvider.notifier).setFilter(
            status: _selectedStatus?.name,
            startDate: _startDate,
            endDate: _endDate,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentReportProvider);
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<ContributionStatus>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Filter Status',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      value: _selectedStatus,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Status')),
                        ...ContributionStatus.values.map(
                          (e) => DropdownMenuItem(value: e, child: Text(e.name)),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedStatus = val);
                        ref.read(paymentReportProvider.notifier).setFilter(
                              status: val?.name,
                              startDate: _startDate,
                              endDate: _endDate,
                            );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: const Text('Dates'),
                    onPressed: _pickDateRange,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _startDate != null
                        ? '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}'
                        : 'All time',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (_startDate != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                        });
                        ref.read(paymentReportProvider.notifier).setFilter(
                              status: _selectedStatus?.name,
                              startDate: null,
                              endDate: null,
                            );
                      },
                      child: const Text('Clear Dates'),
                    ),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Export'),
                    onPressed: () => _exportPayments(state.data),
                  ),
                ],
              )
            ],
          ),
        ),
        Expanded(
          child: state.data.isEmpty && !state.isLoading
              ? const Center(child: Text('No records found.'))
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: state.data.length + (state.hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index >= state.data.length) {
                      return const Center(
                          child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    final item = state.data[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          item.member?.fullName ?? 'Unknown Member',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Amount: ₦${item.contribution.amount.toStringAsFixed(0)}'),
                            Text('Method: ${item.contribution.paymentMethod.name}'),
                            Text('Ref: ${item.contribution.transferReference ?? item.contribution.id}'),
                            Text('Date: ${dateFormat.format(item.contribution.paymentDate)}'),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(item.contribution.status.name,
                              style: const TextStyle(fontSize: 10)),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _exportPayments(List<PaymentReportData> data) async {
    final buffer = StringBuffer();
    buffer.writeln('Reference,Member,Amount,Method,Date,Status');
    for (var r in data) {
      final ref = r.contribution.transferReference ?? r.contribution.id;
      final date = DateFormat('yyyy-MM-dd HH:mm').format(r.contribution.paymentDate);
      buffer.writeln(
          '"$ref","${r.member?.fullName ?? 'Unknown'}",${r.contribution.amount},${r.contribution.paymentMethod.name},"$date",${r.contribution.status.name}');
    }
    await _exportAndShareCsv(
        buffer.toString(), 'Payment_Report_${DateTime.now().millisecondsSinceEpoch}.csv');
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
