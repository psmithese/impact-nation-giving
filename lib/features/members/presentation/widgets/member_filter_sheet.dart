import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/app_user.dart';
import '../../providers/member_providers.dart';

class MemberFilterSheet extends ConsumerStatefulWidget {
  const MemberFilterSheet({super.key});

  @override
  ConsumerState<MemberFilterSheet> createState() => _MemberFilterSheetState();
}

class _MemberFilterSheetState extends ConsumerState<MemberFilterSheet> {
  late UserStatus? _selectedStatus;
  late UserRole? _selectedRole;

  @override
  void initState() {
    super.initState();
    final current = ref.read(membersFilterProvider);
    _selectedStatus = current.statusFilter;
    _selectedRole = current.roleFilter;
  }

  void _apply() {
    ref.read(membersFilterProvider.notifier).update(
      (s) => MembersFilter(
        statusFilter: _selectedStatus,
        roleFilter: _selectedRole,
        searchQuery: s.searchQuery,
      ),
    );
    Navigator.pop(context);
  }

  void _clear() {
    ref.read(membersFilterProvider.notifier).update(
      (s) => MembersFilter(searchQuery: s.searchQuery),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter Members',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              TextButton(onPressed: _clear, child: const Text('Clear all')),
            ],
          ),
          const SizedBox(height: 16),
          Text('Status', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: UserStatus.values.map((s) {
              final label = s.name[0] + s.name.substring(1).toLowerCase();
              return ChoiceChip(
                label: Text(label),
                selected: _selectedStatus == s,
                onSelected: (v) =>
                    setState(() => _selectedStatus = v ? s : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Role', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: UserRole.values.map((r) {
              final label = switch (r) {
                UserRole.SUPER_ADMIN => 'Super Admin',
                UserRole.ADMIN => 'Admin',
                UserRole.FINANCE_OFFICER => 'Finance',
                UserRole.MEMBER => 'Member',
              };
              return ChoiceChip(
                label: Text(label),
                selected: _selectedRole == r,
                onSelected: (v) => setState(() => _selectedRole = v ? r : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _apply,
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
