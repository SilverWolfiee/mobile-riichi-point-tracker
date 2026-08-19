import 'package:flutter_test/flutter_test.dart';
import 'package:riichi_tracker/scoring/score_calculator.dart';

void main() {
  group('calculateBasePoints', () {
    test('30fu 4han is uncapped (1920)', () {
      expect(calculateBasePoints(han: 4, fu: 30), 1920);
    });

    test('mangan cap kicks in at 2000+', () {
      expect(calculateBasePoints(han: 4, fu: 40), 2000);
    });

    test('haneman fixed at 3000 for han 6-7', () {
      expect(calculateBasePoints(han: 6, fu: 30), 3000);
      expect(calculateBasePoints(han: 7, fu: 30), 3000);
    });

    test('yakuman fixed at 8000', () {
      expect(calculateBasePoints(han: 13, fu: 30), 8000);
    });

    test('double yakuman fixed at 16000', () {
      expect(calculateBasePoints(han: 26, fu: 30), 16000);
    });
  });

  group('calculateRonPayment', () {
    test('non-dealer 4han30fu ron = 7700', () {
      final result = calculateRonPayment(han: 4, fu: 30, winnerIsDealer: false);
      expect(result.fromLoser, 7700);
    });

    test('dealer 4han30fu ron = 11600', () {
      final result = calculateRonPayment(han: 4, fu: 30, winnerIsDealer: true);
      expect(result.fromLoser, 11600);
    });

    test('mangan non-dealer ron = 8000', () {
      final result = calculateRonPayment(han: 5, fu: 30, winnerIsDealer: false);
      expect(result.fromLoser, 8000);
    });
  });

  group('calculateTsumoPayment', () {
    test('non-dealer 3han30fu tsumo splits 1000/2000', () {
      final result = calculateTsumoPayment(
        han: 3,
        fu: 30,
        winnerIsDealer: false,
        dealerId: 'dealer',
        nonDealerIds: ['p2', 'p3'],
      );
      expect(result.fromDealer, 2000);
      expect(result.fromNonDealers['p2'], 1000);
      expect(result.fromNonDealers['p3'], 1000);
      expect(result.totalGain, 4000);
    });

    test('dealer tsumo mangan = 4000 all round', () {
      final result = calculateTsumoPayment(
        han: 5,
        fu: 30,
        winnerIsDealer: true,
        dealerId: 'dealer',
        nonDealerIds: ['p2', 'p3', 'p4'],
      );
      expect(result.fromNonDealers['p2'], 4000);
      expect(result.totalGain, 12000);
    });
  });
}