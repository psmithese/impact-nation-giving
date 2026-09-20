import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_provider_util.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../domain/models/public_contributor.dart';
import '../../providers/transparency_providers.dart';

class ContributorsScreen extends ConsumerStatefulWidget {
  final String campaignId;

  const ContributorsScreen({super.key, required this.campaignId});

  @override
  ConsumerState<ContributorsScreen> createState() => _ContributorsScreenState();
}

class _ContributorsScreenState extends ConsumerState<ContributorsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  
  String? _selectedStatus = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitial();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitial() {
    ref.read(contributorsControllerProvider.notifier).loadInitial(
          campaignId: widget.campaignId,
          statusFilter: _selectedStatus == 'ALL' ? null : _selectedStatus,
          searchQuery: _searchQuery,
        );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(contributorsControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(contributorsControllerProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Contributors'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filters & Search
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search contributors...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _loadInitial();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (val) {
                    setState(() => _searchQuery = val.trim());
                    _loadInitial();
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['ALL', 'PLEDGED', 'PARTIAL_PAYMENT', 'FULLY_PAID']
                        .map((status) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(status.replaceAll('_', ' ')),
                                selected: _selectedStatus == status,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedStatus = status);
                                    _loadInitial();
                                  }
                                },
                                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                                labelStyle: TextStyle(
                                  color: _selectedStatus == status
                                      ? AppColors.primaryDark
                                      : theme.colorScheme.onSurface,
                                  fontWeight: _selectedStatus == status ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: state.when(
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(message: e.toString()),
              data: (contributors) {
                if (contributors.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline_rounded,
                              size: 64,
                              color: Colors.grey.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          const Text(
                            'Contributors List is Hidden',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This section is currently not visible to members. '
                            'It has been locked by the administrator. '
                            'Please contact your admin if you need access.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: contributors.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == contributors.length) {
                      return ref.read(contributorsControllerProvider.notifier).hasMore
                          ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                          : const SizedBox.shrink();
                    }

                    return _ContributorCard(contributor: contributors[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributorCard extends StatelessWidget {
  final PublicContributor contributor;

  const _ContributorCard({required this.contributor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy');

    Color statusColor = Colors.grey;
    String statusLabel = 'Unknown';
    if (contributor.status != null) {
      switch (contributor.status) {
        case 'NO_PLEDGE':
          statusColor = Colors.grey;
          statusLabel = 'No Pledge';
          break;
        case 'PLEDGED':
          statusColor = Colors.blue;
          statusLabel = 'Pledged';
          break;
        case 'PARTIAL_PAYMENT':
          statusColor = Colors.orange;
          statusLabel = 'Partial Payment';
          break;
        case 'FULLY_PAID':
          statusColor = AppColors.success;
          statusLabel = 'Fully Paid';
          break;
        case 'CANCELLED':
          statusColor = AppColors.error;
          statusLabel = 'Cancelled';
          break;
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                  backgroundImage: contributor.photoUrl != null ? getImageProvider(contributor.photoUrl!) : null,
                  child: contributor.photoUrl == null
                      ? Icon(Icons.person, color: theme.colorScheme.primary)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contributor.memberName ?? 'Anonymous Member',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (contributor.department != null)
                        Text(
                          contributor.department!,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                    ],
                  ),
                ),
                if (contributor.status != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Financial details if available
            if (contributor.pledgedAmount != null || contributor.amountPaid != null || contributor.outstandingBalance != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (contributor.pledgedAmount != null)
                      _StatColumn(label: 'Pledged', value: currency.format(contributor.pledgedAmount)),
                    if (contributor.amountPaid != null)
                      _StatColumn(label: 'Paid', value: currency.format(contributor.amountPaid), valueColor: AppColors.success),
                    if (contributor.outstandingBalance != null)
                      _StatColumn(label: 'Balance', value: currency.format(contributor.outstandingBalance)),
                  ],
                ),
              ),
            ],

            if (contributor.lastPaymentDate != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 6),
                  Text(
                    'Last payment: ${dateFormat.format(contributor.lastPaymentDate!)}',
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ],

            if (contributor.paymentHistory != null && contributor.paymentHistory!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text('Recent Payments', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...contributor.paymentHistory!.take(3).map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dateFormat.format(p.date), style: theme.textTheme.bodySmall),
                    Text(currency.format(p.amount), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatColumn({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }
}
