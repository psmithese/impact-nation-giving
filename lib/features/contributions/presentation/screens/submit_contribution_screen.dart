import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../pledges/domain/models/pledge.dart';
import '../../domain/models/contribution.dart';
import '../../providers/contribution_providers.dart';

class SubmitContributionScreen extends ConsumerStatefulWidget {
  final Pledge pledge;

  const SubmitContributionScreen({super.key, required this.pledge});

  @override
  ConsumerState<SubmitContributionScreen> createState() =>
      _SubmitContributionScreenState();
}

class _SubmitContributionScreenState
    extends ConsumerState<SubmitContributionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _receivedByController = TextEditingController();

  PaymentMethod _method = PaymentMethod.CASH;
  DateTime _paymentDate = DateTime.now();
  File? _proofFile;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _receivedByController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  Future<void> _pickProof() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.of(ctx).pop();
                final picked = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 600,
                  imageQuality: 50, // compressed for direct Base64 storage
                );
                if (picked != null) {
                  setState(() => _proofFile = File(picked.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.primary),
              title: const Text('Take Photo of Slip / Receipt'),
              onTap: () async {
                Navigator.of(ctx).pop();
                final picked = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 600,
                  imageQuality: 50,
                );
                if (picked != null) {
                  setState(() => _proofFile = File(picked.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(submitContributionProvider.notifier).submit(
            campaignId: widget.pledge.campaignId,
            pledgeId: widget.pledge.id,
            amount: double.parse(_amountController.text.trim()),
            paymentMethod: _method,
            paymentDate: _paymentDate,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
            receivedBy: _method == PaymentMethod.CASH
                ? _receivedByController.text.trim()
                : null,
            proofFile: _proofFile,
          );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Payment submitted! It is pending admin verification.'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(submitContributionProvider).isLoading;
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(symbol: '₦', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Payment'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Outstanding info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.primary.withValues(alpha: 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded,
                      color: AppColors.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Outstanding Balance',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6))),
                        Text(
                          currency.format(widget.pledge.outstandingBalance),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Payment method selector
            Text('Payment Method',
                style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _MethodCard(
                  label: 'Cash',
                  icon: Icons.payments_rounded,
                  selected: _method == PaymentMethod.CASH,
                  onTap: () => setState(() => _method = PaymentMethod.CASH),
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: _MethodCard(
                  label: 'Bank Transfer',
                  icon: Icons.account_balance_rounded,
                  selected: _method == PaymentMethod.BANK_TRANSFER,
                  onTap: () =>
                      setState(() => _method = PaymentMethod.BANK_TRANSFER),
                )),
              ],
            ),
            const SizedBox(height: 24),

            // Amount
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (₦)',
                prefixIcon: Icon(Icons.payments_rounded),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final d = double.tryParse(v);
                if (d == null || d <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Payment date
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Payment Date',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                ),
                child: Text(DateFormat('dd MMM yyyy').format(_paymentDate)),
              ),
            ),
            const SizedBox(height: 16),

            // Note
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                prefixIcon: Icon(Icons.note_alt_rounded),
              ),
              maxLines: 2,
            ),

            // Cash recipient (Required when Cash)
            if (_method == PaymentMethod.CASH) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _receivedByController,
                decoration: const InputDecoration(
                  labelText: 'Person Cash Was Given To (Full Name) *',
                  hintText: 'e.g. Pastor John / Deaconess Grace',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (_method == PaymentMethod.CASH &&
                      (v == null || v.trim().isEmpty)) {
                    return 'Please enter who you handed the cash to';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 6),
              Text(
                'Enter the full name of the church official, pastor, or finance officer who received the cash.',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],

            // Bank Transfer extras
            if (_method == PaymentMethod.BANK_TRANSFER) ...[
              const SizedBox(height: 16),
              // ── Church Bank Account Info ──────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_rounded,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text('Transfer To',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 13,
                            )),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _BankDetailRow(label: 'Bank', value: 'GTBank'),
                    _BankDetailRow(
                        label: 'Account Name',
                        value: 'IMPACT NATION GOSPEL CENTER'),
                    _BankDetailRow(
                        label: 'Account Number', value: '3005256062'),
                    const SizedBox(height: 8),
                    Text(
                      'After transferring to the church account above, please attach your payment slip or receipt screenshot below.',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Proof upload
              GestureDetector(
                onTap: _pickProof,
                child: Container(
                  height: _proofFile == null ? 120 : 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                    ),
                    color: AppColors.primary.withValues(alpha: 0.03),
                  ),
                  child: _proofFile == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_rounded,
                                  size: 38,
                                  color: AppColors.primary
                                      .withValues(alpha: 0.7)),
                              const SizedBox(height: 8),
                              Text('Upload Payment Slip / Receipt',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.primary
                                          .withValues(alpha: 0.9))),
                              const SizedBox(height: 4),
                              Text('Tap to select screenshot or take a photo',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primary
                                          .withValues(alpha: 0.6))),
                            ],
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_proofFile!, fit: BoxFit.cover),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => setState(() => _proofFile = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded,
                                        color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],

            const SizedBox(height: 36),

            FilledButton(
              onPressed: isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Submit for Verification'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MethodCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 20,
                color: selected
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                  color: selected
                      ? AppColors.primary
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                )),
          ],
        ),
      ),
    );
  }
}

class _BankDetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _BankDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
