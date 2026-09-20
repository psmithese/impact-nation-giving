import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../providers/receipt_providers.dart';
import '../../domain/models/receipt.dart';
import '../../services/receipt_service.dart';

class ReceiptViewScreen extends ConsumerWidget {
  final String receiptId;

  const ReceiptViewScreen({super.key, required this.receiptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(receiptByIdProvider(receiptId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Receipt'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: receiptAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (receipt) {
          if (receipt == null) {
            return const Center(child: Text('Receipt not found.'));
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _ReceiptCard(receipt: receipt),
                ),
              ),
              _ActionFooter(receipt: receipt),
            ],
          );
        },
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final Receipt receipt;

  const _ReceiptCard({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IMPACT NATION GOSPEL CENTER',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 195, 208, 239),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Official Receipt',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Text(
                    'VERIFIED',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Receipt Number & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Receipt No.', style: theme.textTheme.labelSmall),
                      Text(
                        receipt.id,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Date', style: theme.textTheme.labelSmall),
                      Text(
                        dateFormat.format(receipt.verifiedAt),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(),
            ),

            // Details
            _DetailRow(label: 'Received From', value: receipt.memberName),
            const SizedBox(height: 16),
            _DetailRow(label: 'Campaign', value: receipt.campaignName),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Payment Method',
              value: receipt.paymentMethod == 'BANK_TRANSFER'
                  ? 'Bank Transfer'
                  : 'Cash',
            ),

            if (receipt.transferReference != null) ...[
              const SizedBox(height: 16),
              _DetailRow(
                label: 'Transfer Ref',
                value: receipt.transferReference!,
              ),
            ],

            if (receipt.receivedBy != null) ...[
              const SizedBox(height: 16),
              _DetailRow(label: 'Cash Given To', value: receipt.receivedBy!),
            ],

            const SizedBox(height: 32),

            // Total Amount
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Amount Paid', style: theme.textTheme.titleMedium),
                  Text(
                    currency.format(receipt.amount),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 64, 90, 177),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _ActionFooter extends StatefulWidget {
  final Receipt receipt;
  const _ActionFooter({required this.receipt});

  @override
  State<_ActionFooter> createState() => _ActionFooterState();
}

class _ActionFooterState extends State<_ActionFooter> {
  bool _isGenerating = false;
  Uint8List? _pdfData;

  Future<void> _generatePdf() async {
    if (_pdfData != null) return;
    setState(() => _isGenerating = true);
    try {
      _pdfData = await ReceiptService.generateReceiptPdf(widget.receipt);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _print() async {
    await _generatePdf();
    if (_pdfData != null) {
      await Printing.layoutPdf(
        onLayout: (format) async => _pdfData!,
        name: '${widget.receipt.id}.pdf',
      );
    }
  }

  Future<void> _share() async {
    await _generatePdf();
    if (_pdfData != null) {
      await Printing.sharePdf(
        bytes: _pdfData!,
        filename: '${widget.receipt.id}.pdf',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isGenerating ? null : _print,
                icon: const Icon(Icons.print_rounded),
                label: const Text('Print'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton.icon(
                onPressed: _isGenerating ? null : _share,
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share PDF'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
