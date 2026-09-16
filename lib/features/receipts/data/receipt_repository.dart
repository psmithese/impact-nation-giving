import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/receipt.dart';

class ReceiptRepository {
  final FirebaseFirestore _firestore;

  ReceiptRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _receipts =>
      _firestore.collection('receipts');

  /// Fetches a receipt by its unique receiptId. 
  /// Used for both members viewing their receipts and public verification.
  Future<Receipt?> getReceiptById(String receiptId) async {
    final doc = await _receipts.doc(receiptId).get();
    if (!doc.exists) return null;
    return Receipt.fromMap(doc.data()!, doc.id);
  }
}
