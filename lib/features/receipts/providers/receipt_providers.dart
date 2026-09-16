import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/receipt_repository.dart';
import '../domain/models/receipt.dart';

final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  return ReceiptRepository();
});

/// Fetches a receipt by ID for view or verification.
final receiptByIdProvider =
    FutureProvider.family<Receipt?, String>((ref, receiptId) async {
  return ref.read(receiptRepositoryProvider).getReceiptById(receiptId);
});
