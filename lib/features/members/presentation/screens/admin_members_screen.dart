import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/member_providers.dart';
import '../widgets/member_card.dart';
import '../widgets/member_filter_sheet.dart';

class AdminMembersScreen extends ConsumerStatefulWidget {
  const AdminMembersScreen({super.key});

  @override
  ConsumerState<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends ConsumerState<AdminMembersScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(membersNotifierProvider.notifier).loadMore();
    }
  }

  void _onSearch(String query) {
    ref.read(membersFilterProvider.notifier).update(
          (state) => state.copyWith(searchQuery: query),
        );
  }

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const MemberFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersNotifierProvider);
    final filter = ref.watch(membersFilterProvider);
    final hasActiveFilter =
        filter.statusFilter != null || filter.roleFilter != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                tooltip: 'Filter',
                icon: const Icon(Icons.tune),
                onPressed: _openFilter,
              ),
              if (hasActiveFilter)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search by name or email…',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _onSearch('');
                    },
                  ),
              ],
              onChanged: _onSearch,
            ),
          ),
        ),
      ),
      body: membersAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () =>
              ref.read(membersNotifierProvider.notifier).refresh(),
        ),
        data: (members) {
          if (members.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text(
                    'No members found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(membersNotifierProvider.notifier).refresh(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              itemCount: members.length + 1,
              itemBuilder: (context, index) {
                if (index == members.length) {
                  // Pagination footer
                  return ref
                          .read(membersNotifierProvider.notifier)
                          .hasMore
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : const SizedBox(height: 16);
                }

                final member = members[index];
                return MemberCard(
                  member: member,
                  onTap: () =>
                      context.push('/admin/members/${member.uid}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
