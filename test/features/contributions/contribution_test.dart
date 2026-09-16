import 'package:flutter_test/flutter_test.dart';
import 'package:impact_nation_fund_raising/features/contributions/domain/models/contribution.dart';

void main() {
  final baseDate = DateTime(2026, 1, 1);

  group('Contribution model', () {
    test('starts as PENDING_VERIFICATION — never affects totals until verified', () {
      final c = Contribution(
        id: '1',
        campaignId: 'c1',
        pledgeId: 'p1',
        userId: 'u1',
        amount: 100000,
        paymentMethod: PaymentMethod.CASH,
        paymentDate: baseDate,
        status: ContributionStatus.PENDING_VERIFICATION,
        createdAt: baseDate,
        updatedAt: baseDate,
      );

      expect(c.isPending, true);
      expect(c.isVerified, false);
      expect(c.isRejected, false);
    });

    test('VERIFIED contribution is marked correctly', () {
      final c = Contribution(
        id: '1',
        campaignId: 'c1',
        pledgeId: 'p1',
        userId: 'u1',
        amount: 200000,
        paymentMethod: PaymentMethod.BANK_TRANSFER,
        paymentDate: baseDate,
        status: ContributionStatus.VERIFIED,
        verifiedBy: 'admin-uid',
        verifiedAt: baseDate,
        createdAt: baseDate,
        updatedAt: baseDate,
      );

      expect(c.isVerified, true);
      expect(c.isPending, false);
      expect(c.amount, 200000.0);
      expect(c.verifiedBy, 'admin-uid');
    });

    test('REJECTED contribution retains rejection reason', () {
      final c = Contribution(
        id: '1',
        campaignId: 'c1',
        pledgeId: 'p1',
        userId: 'u1',
        amount: 50000,
        paymentMethod: PaymentMethod.CASH,
        paymentDate: baseDate,
        status: ContributionStatus.REJECTED,
        rejectionReason: 'Duplicate submission',
        createdAt: baseDate,
        updatedAt: baseDate,
      );

      expect(c.isRejected, true);
      expect(c.rejectionReason, 'Duplicate submission');
    });

    test('fromMap correctly parses all fields', () {
      final map = {
        'campaignId': 'c1',
        'pledgeId': 'p1',
        'userId': 'u1',
        'amount': 500000,
        'paymentMethod': 'BANK_TRANSFER',
        'paymentDate': baseDate.millisecondsSinceEpoch,
        'note': 'Monthly installment',
        'bankName': 'Zenith Bank',
        'transferReference': 'TRF12345',
        'proofUrl': null,
        'status': 'PENDING_VERIFICATION',
        'verifiedBy': null,
        'verifiedAt': null,
        'rejectionReason': null,
        'createdAt': baseDate.millisecondsSinceEpoch,
        'updatedAt': baseDate.millisecondsSinceEpoch,
      };

      final c = Contribution.fromMap(map, 'test-id');

      expect(c.id, 'test-id');
      expect(c.amount, 500000.0);
      expect(c.paymentMethod, PaymentMethod.BANK_TRANSFER);
      expect(c.bankName, 'Zenith Bank');
      expect(c.transferReference, 'TRF12345');
      expect(c.status, ContributionStatus.PENDING_VERIFICATION);
      expect(c.note, 'Monthly installment');
    });

    test('toMap serializes status correctly', () {
      final c = Contribution(
        id: 'x',
        campaignId: 'c1',
        pledgeId: 'p1',
        userId: 'u1',
        amount: 300000,
        paymentMethod: PaymentMethod.CASH,
        paymentDate: baseDate,
        status: ContributionStatus.PENDING_VERIFICATION,
        createdAt: baseDate,
        updatedAt: baseDate,
      );

      final map = c.toMap();
      expect(map['status'], 'PENDING_VERIFICATION');
      expect(map['amount'], 300000.0);
      expect(map['paymentMethod'], 'CASH');
    });

    test('copyWith only updates specified fields', () {
      final original = Contribution(
        id: 'x',
        campaignId: 'c1',
        pledgeId: 'p1',
        userId: 'u1',
        amount: 300000,
        paymentMethod: PaymentMethod.CASH,
        paymentDate: baseDate,
        status: ContributionStatus.PENDING_VERIFICATION,
        createdAt: baseDate,
        updatedAt: baseDate,
      );

      final updated = original.copyWith(
        status: ContributionStatus.VERIFIED,
        verifiedBy: 'admin-001',
      );

      expect(updated.status, ContributionStatus.VERIFIED);
      expect(updated.verifiedBy, 'admin-001');
      // Unchanged fields
      expect(updated.amount, original.amount);
      expect(updated.userId, original.userId);
      expect(updated.paymentMethod, original.paymentMethod);
    });
  });
}
