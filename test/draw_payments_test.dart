import 'package:flutter_test/flutter_test.dart';
import 'package:riichi_tracker/scoring/draw_payments.dart';

void main() {
  group('calculateNotenPayments', () {
    final players = ['p1', 'p2', 'p3', 'p4'];

    test('1 tenpai gets 3000, others pay 1000 each', () {
      final result = calculateNotenPayments(allPlayerIds: players, tenpaiPlayerIds: ['p1']);
      expect(result['p1'], 3000);
      expect(result['p2'], -1000);
      expect(result['p3'], -1000);
      expect(result['p4'], -1000);
    });

    test('2 tenpai get 1500 each, others pay 1500 each', () {
      final result = calculateNotenPayments(allPlayerIds: players, tenpaiPlayerIds: ['p1', 'p2']);
      expect(result['p1'], 1500);
      expect(result['p2'], 1500);
      expect(result['p3'], -1500);
      expect(result['p4'], -1500);
    });

    test('3 tenpai get 1000 each, sole noten pays 3000', () {
      final result = calculateNotenPayments(allPlayerIds: players, tenpaiPlayerIds: ['p1', 'p2', 'p3']);
      expect(result['p1'], 1000);
      expect(result['p2'], 1000);
      expect(result['p3'], 1000);
      expect(result['p4'], -3000);
    });

    test('all tenpai or all noten results in no payment', () {
      final allTenpai = calculateNotenPayments(allPlayerIds: players, tenpaiPlayerIds: players);
      final noneTenpai = calculateNotenPayments(allPlayerIds: players, tenpaiPlayerIds: []);
      for (final id in players) {
        expect(allTenpai[id], 0);
        expect(noneTenpai[id], 0);
      }
    });
  });
}