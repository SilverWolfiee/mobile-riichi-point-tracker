import 'dart:math';

int _fixedBasePoints(int han) {
  if (han >= 26) return 16000;
  if (han >= 13) return 8000; //yakuman
  if (han >= 11) return 6000; //sanbaiman
  if (han >= 8) return 4000; //baiman
  if (han >= 6) return 3000; //haneman
  return 2000; //mangan
}

int calculateBasePoints({required int han, required int fu}) {
  if (han >= 5) {
    return _fixedBasePoints(han);
  }
  final raw = fu * pow(2, 2 + han).toInt();
  return raw >= 2000 ? 2000 : raw;
}

int _roundUpTo100(int value) => ((value + 99) ~/ 100) * 100;

class WinPayments {
  final int fromDealer;
  final Map<String, int> fromNonDealers;
  final int fromLoser;
  final int totalGain;
  const WinPayments({
    this.fromDealer = 0,
    this.fromNonDealers = const {},
    this.fromLoser = 0,
    required this.totalGain,
  });
}

WinPayments calculateRonPayment({
  required int han,
  required int fu,
  required bool winnerIsDealer,
  int yakumanMultiplier = 1,
}) {
  final base = calculateBasePoints(han: han, fu: fu) * yakumanMultiplier;
  final multiplier = winnerIsDealer ? 6 : 4;
  final payment = _roundUpTo100(base * multiplier);
  return WinPayments(fromLoser: payment, totalGain: payment);
}

WinPayments calculateTsumoPayment({
  required int han,
  required int fu,
  required bool winnerIsDealer,
  required String dealerId,
  required List<String> nonDealerIds,
  int yakumanMultiplier = 1,
}) {
  final base = calculateBasePoints(han: han, fu: fu) * yakumanMultiplier;
  if (winnerIsDealer) {
    final each = _roundUpTo100(base * 2);
    final payments = {for (final id in nonDealerIds) id: each};
    return WinPayments(
      fromNonDealers: payments,
      totalGain: payments.values.fold(0, (a, b) => a + b),
    );
  } else {
    final dealerPays = _roundUpTo100(base * 2);
    final each = _roundUpTo100(base * 1);
    final payments = {
      dealerId: dealerPays,
      for (final id in nonDealerIds) id: each,
    };
    return WinPayments(
      fromDealer: dealerPays,
      fromNonDealers: payments,
      totalGain: payments.values.fold(0, (a, b) => a + b),
    );
  }
}
