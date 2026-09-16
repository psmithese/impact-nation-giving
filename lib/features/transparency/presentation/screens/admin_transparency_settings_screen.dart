import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../domain/models/visibility_settings.dart';
import '../../providers/transparency_providers.dart';

class AdminTransparencySettingsScreen extends ConsumerStatefulWidget {
  const AdminTransparencySettingsScreen({super.key});

  @override
  ConsumerState<AdminTransparencySettingsScreen> createState() =>
      _AdminTransparencySettingsScreenState();
}

class _AdminTransparencySettingsScreenState
    extends ConsumerState<AdminTransparencySettingsScreen> {
  VisibilitySettings? _settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(visibilitySettingsProvider);
    final isSaving = ref.watch(visibilitySettingsControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Transparency Settings'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: settingsAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (initialSettings) {
          _settings ??= initialSettings;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'These settings control exactly what financial data is stored in the public contributors collection. Disabling a field completely removes it from public access instantly.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.85)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _SectionHeader(title: 'Identity Visibility'),
              _ToggleRow(
                title: 'Show Member Name',
                value: _settings!.showMemberName,
                onChanged: (v) => setState(() => _settings = _settings!.copyWith(showMemberName: v)),
              ),
              _ToggleRow(
                title: 'Show Profile Photo',
                value: _settings!.showProfilePhoto,
                onChanged: (v) => setState(() => _settings = _settings!.copyWith(showProfilePhoto: v)),
              ),
              _ToggleRow(
                title: 'Show Department',
                value: _settings!.showDepartment,
                onChanged: (v) => setState(() => _settings = _settings!.copyWith(showDepartment: v)),
              ),

              const SizedBox(height: 24),
              _SectionHeader(title: 'Financial Visibility'),
              _ToggleRow(
                title: 'Show Pledge Amount',
                value: _settings!.showPledgeAmount,
                onChanged: (v) => setState(() => _settings = _settings!.copyWith(showPledgeAmount: v)),
              ),
              _ToggleRow(
                title: 'Show Amount Paid',
                value: _settings!.showAmountPaid,
                onChanged: (v) => setState(() => _settings = _settings!.copyWith(showAmountPaid: v)),
              ),
              _ToggleRow(
                title: 'Show Outstanding Balance',
                value: _settings!.showOutstandingBalance,
                onChanged: (v) => setState(() => _settings = _settings!.copyWith(showOutstandingBalance: v)),
              ),

              const SizedBox(height: 24),
              _SectionHeader(title: 'Status Visibility'),
              _ToggleRow(
                title: 'Show Payment Status',
                value: _settings!.showPaymentStatus,
                onChanged: (v) => setState(() => _settings = _settings!.copyWith(showPaymentStatus: v)),
              ),
              _ToggleRow(
                title: 'Show Last Payment Date',
                value: _settings!.showPaymentDate,
                onChanged: (v) => setState(() => _settings = _settings!.copyWith(showPaymentDate: v)),
              ),
              _ToggleRow(
                title: 'Show Payment History',
                value: _settings!.showPaymentHistory,
                onChanged: (v) => setState(() => _settings = _settings!.copyWith(showPaymentHistory: v)),
              ),

              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: isSaving
                    ? null
                    : () async {
                        try {
                          await ref
                              .read(visibilitySettingsControllerProvider.notifier)
                              .updateSettings(_settings!);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Settings saved & synced globally!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                icon: isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded),
                label: Text(isSaving ? 'Syncing...' : 'Save & Sync Contributors'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }
}
