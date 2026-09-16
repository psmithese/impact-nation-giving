import 'package:flutter_test/flutter_test.dart';
import 'package:impact_nation_fund_raising/features/receipts/domain/models/receipt.dart';

void main() {
  final baseDate = DateTime(2026, 1, 1);

  group('Receipt model', () {
    test('fromMap correctly parses all fields', () {
      final map = {
        'contributionId': 'contrib-123',
        'campaignName': 'Church Rent',
        'memberName': 'John Doe',
        'amount': 50000.0,
        'paymentMethod': 'CASH',
        'transferReference': null,
        'paymentDate': baseDate.millisecondsSinceEpoch,
        'verifiedAt': baseDate.millisecondsSinceEpoch,
      };

      final r = Receipt.fromMap(map, 'RCPT-TEST');

      expect(r.id, 'RCPT-TEST');
      expect(r.contributionId, 'contrib-123');
      expect(r.campaignName, 'Church Rent');
      expect(r.memberName, 'John Doe');
      expect(r.amount, 50000.0);
      expect(r.paymentMethod, 'CASH');
      expect(r.transferReference, null);
      expect(r.paymentDate, baseDate);
      expect(r.verifiedAt, baseDate);
    });

    test('toMap serializes correctly', () {
      final r = Receipt(
        id: 'RCPT-TEST',
        contributionId: 'contrib-123',
        campaignName: 'Church Rent',
        memberName: 'John Doe',
        amount: 25000.0,
        paymentMethod: 'BANK_TRANSFER',
        transferReference: 'REF-XYZ',
        paymentDate: baseDate,
        verifiedAt: baseDate,
      );

      final map = r.toMap();
      
      expect(map['contributionId'], 'contrib-123');
      expect(map['campaignName'], 'Church Rent');
      expect(map['memberName'], 'John Doe');
      expect(map['amount'], 25000.0);
      expect(map['paymentMethod'], 'BANK_TRANSFER');
      expect(map['transferReference'], 'REF-XYZ');
      expect(map['paymentDate'], baseDate.millisecondsSinceEpoch);
      expect(map['verifiedAt'], baseDate.millisecondsSinceEpoch);
    });
  });
}
