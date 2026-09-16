import 'package:flutter_test/flutter_test.dart';
import 'package:impact_nation_fund_raising/features/pledges/domain/models/pledge.dart';

void main() {
  group('Pledge Financial Calculations & Status', () {
    test('NO_PLEDGE or PLEDGED status when amountPaid is 0', () {
      final pledge = Pledge(
        id: '1',
        campaignId: 'c1',
        userId: 'u1',
        pledgedAmount: 500000.0,
        amountPaid: 0.0,
        status: PledgeStatus.PLEDGED,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(pledge.outstandingBalance, 500000.0);
      expect(pledge.computedStatus, PledgeStatus.PLEDGED);
    });

    test('PARTIAL_PAYMENT status when amountPaid > 0 but < pledgedAmount', () {
      final pledge = Pledge(
        id: '1',
        campaignId: 'c1',
        userId: 'u1',
        pledgedAmount: 500000.0,
        amountPaid: 200000.0,
        status: PledgeStatus.PLEDGED, // manual status is overridden by computation
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(pledge.outstandingBalance, 300000.0);
      expect(pledge.computedStatus, PledgeStatus.PARTIAL_PAYMENT);
    });

    test('FULLY_PAID status when amountPaid == pledgedAmount', () {
      final pledge = Pledge(
        id: '1',
        campaignId: 'c1',
        userId: 'u1',
        pledgedAmount: 500000.0,
        amountPaid: 500000.0,
        status: PledgeStatus.PLEDGED,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(pledge.outstandingBalance, 0.0);
      expect(pledge.computedStatus, PledgeStatus.FULLY_PAID);
    });

    test('FULLY_PAID status when amountPaid > pledgedAmount (overpaid)', () {
      final pledge = Pledge(
        id: '1',
        campaignId: 'c1',
        userId: 'u1',
        pledgedAmount: 500000.0,
        amountPaid: 600000.0,
        status: PledgeStatus.PLEDGED,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Outstanding balance clamps at 0.0
      expect(pledge.outstandingBalance, 0.0); 
      expect(pledge.computedStatus, PledgeStatus.FULLY_PAID);
    });

    test('CANCELLED status is respected regardless of amounts', () {
      final pledge = Pledge(
        id: '1',
        campaignId: 'c1',
        userId: 'u1',
        pledgedAmount: 500000.0,
        amountPaid: 100000.0,
        status: PledgeStatus.CANCELLED,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(pledge.outstandingBalance, 400000.0);
      expect(pledge.computedStatus, PledgeStatus.CANCELLED);
    });
  });
}
