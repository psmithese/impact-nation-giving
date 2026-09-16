import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/campaign_providers.dart';
import '../../domain/models/campaign.dart';

class CreateEditCampaignScreen extends ConsumerStatefulWidget {
  final Campaign? campaign; // If null, creating new.

  const CreateEditCampaignScreen({super.key, this.campaign});

  @override
  ConsumerState<CreateEditCampaignScreen> createState() =>
      _CreateEditCampaignScreenState();
}

class _CreateEditCampaignScreenState
    extends ConsumerState<CreateEditCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _targetController;
  
  late DateTime _startDate;
  late DateTime _endDate;
  late CampaignStatus _status;

  @override
  void initState() {
    super.initState();
    final c = widget.campaign;
    _nameController = TextEditingController(text: c?.name ?? '');
    _descController = TextEditingController(text: c?.description ?? '');
    _targetController =
        TextEditingController(text: c?.targetAmount.toStringAsFixed(0) ?? '');
    _startDate = c?.startDate ?? DateTime.now();
    _endDate = c?.endDate ?? DateTime.now().add(const Duration(days: 30));
    _status = c?.status ?? CampaignStatus.DRAFT;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final target = double.tryParse(_targetController.text) ?? 0.0;
    final isNew = widget.campaign == null;

    if (isNew) {
      await ref.read(campaignControllerProvider.notifier).createCampaign(
            name: _nameController.text.trim(),
            description: _descController.text.trim(),
            targetAmount: target,
            startDate: _startDate,
            endDate: _endDate,
            status: _status,
          );
    } else {
      final updated = widget.campaign!.copyWith(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        targetAmount: target,
        startDate: _startDate,
        endDate: _endDate,
        status: _status,
      );
      await ref.read(campaignControllerProvider.notifier).updateCampaign(updated);
    }

    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isNew ? 'Campaign created' : 'Campaign updated'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(campaignControllerProvider);
    final isLoading = state.isLoading;
    final isNew = widget.campaign == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'New Campaign' : 'Edit Campaign'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Campaign Name',
                prefixIcon: Icon(Icons.campaign),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetController,
              decoration: const InputDecoration(
                labelText: 'Target Amount (₦)',
                prefixIcon: Icon(Icons.payments_rounded),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v!.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Must be a number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Status dropdown
            DropdownButtonFormField<CampaignStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.info_outline),
              ),
              items: CampaignStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.name),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _status = val);
              },
            ),
            
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text('${_endDate.day}/${_endDate.month}/${_endDate.year}'),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            FilledButton(
              onPressed: isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(isNew ? 'Create Campaign' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
