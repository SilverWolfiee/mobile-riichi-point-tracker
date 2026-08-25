import 'package:riichi_tracker/scoring/game_event.dart';

import 'score_calculator.dart';
import 'draw_payments.dart';
import 'round_state.dart';

class GameState {
  final Map<String, int> scores;
  final RoundState roundState;
  final Set<String> riichiDeclaredIds;

  const GameState({
    required this.scores,
    required this.roundState,
    this.riichiDeclaredIds = const {},
  });

  GameState copyWith({
    Map<String, int>? scores,
    RoundState? roundState,
    Set<String>? riichiDeclaredIds,
  }) {
    return GameState(
      scores: scores ?? this.scores,
      roundState: roundState ?? this.roundState,
      riichiDeclaredIds: riichiDeclaredIds ?? this.riichiDeclaredIds,
    );
  }
}

GameState buildIntitialState({
  required List<String> playerIdsInSeatOrder,
  required int startingScore,
}) {
  return GameState(
    scores: {for (final id in playerIdsInSeatOrder) id: startingScore},
    roundState: const RoundState(
      rotationIndex: 0,
      honba: 0,
      riichiSticksPot: 0,
    ),
  );
}

GameState applyEvents({
  required List<GameEvent> events,
  required List<String> playerIdsInSeatOrder,
  required int startingScore,
  required GameLength length,
}) {
  var state = buildIntitialState(
    playerIdsInSeatOrder: playerIdsInSeatOrder,
    startingScore: startingScore,
  );
  for (final event in events) {
    state = _applyEvent(
      state: state,
      event: event,
      playerIdsInSeatOrder: playerIdsInSeatOrder,
      startingScore: startingScore,
      length: length,
    );
  }
  return state;
}

GameState _applyEvent({
  required GameState state,
  required GameEvent event,
  required List<String> playerIdsInSeatOrder,
  required int startingScore,
  required GameLength length,
}) {
  final dealerId = playerIdsInSeatOrder[state.roundState.dealerSeatIndex];
  switch (event.type) {
    case 'RIICHI_DECLARED':
      final playerId = event.payload['playerId'] as String;
      final scores = Map<String, int>.from(state.scores);
      scores[playerId] = scores[playerId]! - 1000;
      return state.copyWith(
        scores: scores,
        roundState: state.roundState.copyWith(
          riichiSticksPot: state.roundState.riichiSticksPot + 1000,
        ),
        riichiDeclaredIds: {...state.riichiDeclaredIds, playerId},
      );
    case 'WIN':
      final winnerId = event.payload['winnerId'] as String;
      final isTsumo = event.payload['isTsumo'] as bool;
      final han = event.payload['han'] as int;
      final fu = event.payload['fu'] as int;
      final winnerIsDealer = winnerId == dealerId;
      final honba = state.roundState.honba;
      final pot = state.roundState.riichiSticksPot;

      final scores = Map<String, int>.from(state.scores);

      if (isTsumo) {
        final others = playerIdsInSeatOrder
            .where((id) => id != winnerId)
            .toList();
        final nonDealerIds = others.where((id) => id != dealerId).toList();
        final payments = calculateTsumoPayment(
          han: han,
          fu: fu,
          winnerIsDealer: winnerIsDealer,
          dealerId: dealerId,
          nonDealerIds: winnerIsDealer ? others : nonDealerIds,
        );
        final honbaEach = honba * 100;
        var totalGain = payments.totalGain + honba * 300;
        for (final id in payments.fromNonDealers.keys) {
          scores[id] = scores[id]! - payments.fromNonDealers[id]! - honbaEach;
        }
        scores[winnerId] = scores[winnerId]! + totalGain + pot;
      } else {
        final loserId = event.payload['loserId'] as String;
        final payment = calculateRonPayment(
          han: han,
          fu: fu,
          winnerIsDealer: winnerIsDealer,
        );
        final totalGain = payment.totalGain + honba * 300;
        scores[loserId] = scores[loserId]! - payment.fromLoser - honba * 300;
        scores[winnerId] = scores[winnerId]! + totalGain + pot;
      }

      final nextRound = resolveRoundEnd(
        current: state.roundState,
        length: length,
        dealerWon: winnerIsDealer,
        isDraw: false,
        dealerTenpai: false,
        anyWin: true,
        scoresAfterHand: playerIdsInSeatOrder.map((id) => scores[id]!).toList(),
        startingScore: startingScore,
      );

      return GameState(scores: scores, roundState: nextRound);
    case 'EXHAUSTIVE_DRAW':
      final tenpaiIds = List<String>.from(
        event.payload['tenpaiPlayerIds'] as List,
      );
      final payments = calculateNotenPayments(
        allPlayerIds: playerIdsInSeatOrder,
        tenpaiPlayerIds: tenpaiIds,
      );
      final scores = Map<String, int>.from(state.scores);
      for (final id in playerIdsInSeatOrder) {
        scores[id] = scores[id]! + payments[id]!;
      }

      final nextRound = resolveRoundEnd(
        current: state.roundState,
        length: length,
        dealerWon: false,
        isDraw: true,
        dealerTenpai: tenpaiIds.contains(dealerId),
        anyWin: false,
        scoresAfterHand: playerIdsInSeatOrder.map((id) => scores[id]!).toList(),
        startingScore: startingScore,
      );

      return GameState(scores: scores, roundState: nextRound, riichiDeclaredIds: {});

    case 'POINT_ADJUSTMENT':
      final playerId = event.payload['playerId'] as String;
      final delta = event.payload['delta'] as int;
      final scores = Map<String, int>.from(state.scores);
      scores[playerId] = scores[playerId]! + delta;
      return state.copyWith(scores: scores);
    case 'FORCE_END':
      final nextRound = resolveRoundEnd(
        current: state.roundState,
        length: length,
        dealerWon: false,
        isDraw: false,
        dealerTenpai: false,
        anyWin: false,
        scoresAfterHand: playerIdsInSeatOrder
            .map((id) => state.scores[id]!)
            .toList(),
        startingScore: startingScore,
        forceEnd: true,
      );
      return GameState(scores: state.scores, roundState: nextRound);
    default:
      return state;
  }
}
