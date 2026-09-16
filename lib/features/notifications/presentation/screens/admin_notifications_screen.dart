import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/notification_providers.dart';
import '../../../campaigns/providers/campaign_providers.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends ConsumerState<AdminNotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  
  String _targetType = 'ALL';
  String? _selectedCampaignId;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_targetType == 'CAMPAIGN' && _selectedCampaignId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a campaign')),
      );
      return;
    }

    await ref.read(notificationControllerProvider.notifier).sendAnnouncement(
      _titleController.text,
      _bodyController.text,
      _targetType,
      targetId: _selectedCampaignId,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement sent successfully')),
      );
      _titleController.clear();
      _bodyController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationControllerProvider);
    final theme = Theme.of(context);
    final campaignsAsync = ref.watch(allCampaignsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Admin Announcements'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Send Announcement', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Send push notifications and in-app alerts to users.'),
              const SizedBox(height: 24),
              
              // Target Selection
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Target Audience',
                  border: OutlineInputBorder(),
                ),
                initialValue: _targetType,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('All Members')),
                  DropdownMenuItem(value: 'CAMPAIGN', child: Text('Campaign Participants')),
                  DropdownMenuItem(value: 'GROUP', child: Text('Specific Group')),
                ],
                onChanged: (val) {
                  setState(() {
                    _targetType = val!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              if (_targetType == 'CAMPAIGN') ...[
                campaignsAsync.when(
                  data: (campaigns) => DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Campaign',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedCampaignId,
                    items: campaigns.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCampaignId = val;
                      });
                    },
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error loading campaigns: $e'),
                ),
                const SizedBox(height: 16),
              ],
              
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'Message Body',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: state.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Send Announcement'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
