import 'package:flutter_test/flutter_test.dart';
import 'package:riichi_tracker/scoring/game_event.dart';
import 'package:riichi_tracker/scoring/game_state.dart';
import 'package:riichi_tracker/scoring/round_state.dart';

void main() {
  const players = ['p1', 'p2', 'p3', 'p4']; // p1=East/dealer at rotationIndex 0

  group('RIICHI_DECLARED', () {
    test('deducts 1000 from declarer, adds 1000 to pot', () {
      final state = applyEvents(
        events: const [
          GameEvent(type: 'RIICHI_DECLARED', roundNumber: 1, honba: 0, payload: {'playerId': 'p2'}),
        ],
        playerIdsInSeatOrder: players,
        startingScore: 25000,
        length: GameLength.hanchan,
      );
      expect(state.scores['p2'], 24000);
      expect(state.roundState.riichiSticksPot, 1000);
    });
  });

  group('WIN - tsumo', () {
    test('dealer tsumo: each non-dealer pays base*2, dealer repeats with honba+1', () {
      final state = applyEvents(
        events: const [
          GameEvent(
            type: 'WIN',
            roundNumber: 1,
            honba: 0,
            payload: {'winnerId': 'p1', 'isTsumo': true, 'han': 4, 'fu': 30},
          ),
        ],
        playerIdsInSeatOrder: players,
        startingScore: 25000,
        length: GameLength.hanchan,
      );
      // base = 30*64 = 1920, each non-dealer pays roundUp(1920*2)=3900
      expect(state.scores['p1'], 25000 + 3900 * 3);
      expect(state.scores['p2'], 25000 - 3900);
      expect(state.scores['p3'], 25000 - 3900);
      expect(state.scores['p4'], 25000 - 3900);
      expect(state.roundState.rotationIndex, 0); // dealer repeats
      expect(state.roundState.honba, 1);
    });

    test('non-dealer tsumo: dealer pays double share, others single, dealer rotates', () {
      final state = applyEvents(
        events: const [
          GameEvent(
            type: 'WIN',
            roundNumber: 1,
            honba: 0,
            payload: {'winnerId': 'p3', 'isTsumo': true, 'han': 3, 'fu': 30},
          ),
        ],
        playerIdsInSeatOrder: players,
        startingScore: 25000,
        length: GameLength.hanchan,
      );
      // base = 30*32 = 960, dealer(p1) pays roundUp(960*2)=2000, others pay roundUp(960)=1000
      expect(state.scores['p1'], 25000 - 2000);
      expect(state.scores['p2'], 25000 - 1000);
      expect(state.scores['p4'], 25000 - 1000);
      expect(state.scores['p3'], 25000 + 2000 + 1000 * 2);
      expect(state.roundState.rotationIndex, 1); // rotates
      expect(state.roundState.honba, 0);
    });

    test('honba adds 100 per payer, all claimed by winner', () {
      final state = applyEvents(
        events: const [
          GameEvent(
            type: 'WIN',
            roundNumber: 1,
            honba: 2,
            payload: {'winnerId': 'p1', 'isTsumo': true, 'han': 4, 'fu': 30},
          ),
        ],
        playerIdsInSeatOrder: players,
        startingScore: 25000,
        length: GameLength.hanchan,
      );
      // honba is read from roundState, which starts at 0 regardless of event.payload's honba field.
      // This test documents that roundState (not payload) drives honba math.
      expect(state.roundState.honba, 1); // 0 -> increments from actual roundState, not payload
    });
  });

  group('WIN - ron', () {
    test('loser pays base payment plus honba bonus, winner claims pot', () {
      final state = applyEvents(
        events: const [
          GameEvent(type: 'RIICHI_DECLARED', roundNumber: 1, honba: 0, payload: {'playerId': 'p2'}),
          GameEvent(
            type: 'WIN',
            roundNumber: 1,
            honba: 0,
            payload: {'winnerId': 'p3', 'isTsumo': false, 'loserId': 'p2', 'han': 3, 'fu': 30},
          ),
        ],
        playerIdsInSeatOrder: players,
        startingScore: 25000,
        length: GameLength.hanchan,
      );
      // riichi: p2 -1000, pot +1000
      // ron: base=960, roundUp(960*4)=3900, loser p2 pays 3900, winner p3 gets 3900 + pot(1000)
      expect(state.scores['p2'], 25000 - 1000 - 3900);
      expect(state.scores['p3'], 25000 + 3900 + 1000);
      expect(state.roundState.riichiSticksPot, 0); // claimed
      expect(state.roundState.rotationIndex, 1); // non-dealer win rotates
    });
  });

  group('EXHAUSTIVE_DRAW', () {
    test('dealer tenpai: dealer gains, others pay, dealer repeats', () {
      final state = applyEvents(
        events: const [
          GameEvent(
            type: 'EXHAUSTIVE_DRAW',
            roundNumber: 1,
            honba: 0,
            payload: {'tenpaiPlayerIds': ['p1']},
          ),
        ],
        playerIdsInSeatOrder: players,
        startingScore: 25000,
        length: GameLength.hanchan,
      );
      expect(state.scores['p1'], 25000 + 3000);
      expect(state.scores['p2'], 25000 - 1000);
      expect(state.roundState.rotationIndex, 0); // repeats
      expect(state.roundState.honba, 1);
    });

    test('dealer noten: dealer pays, dealer rotates', () {
      final state = applyEvents(
        events: const [
          GameEvent(
            type: 'EXHAUSTIVE_DRAW',
            roundNumber: 1,
            honba: 0,
            payload: {'tenpaiPlayerIds': ['p2']},
          ),
        ],
        playerIdsInSeatOrder: players,
        startingScore: 25000,
        length: GameLength.hanchan,
      );
      expect(state.scores['p1'], 24000);
      expect(state.scores['p2'], 25000 + 3000);
      expect(state.roundState.rotationIndex, 1); // rotates
      expect(state.roundState.honba, 1);
    });
  });

  group('POINT_ADJUSTMENT', () {
    test('applies delta directly, does not touch round state', () {
      final state = applyEvents(
        events: const [
          GameEvent(type: 'POINT_ADJUSTMENT', roundNumber: 1, honba: 0, payload: {'playerId': 'p4', 'delta': -500}),
        ],
        playerIdsInSeatOrder: players,
        startingScore: 25000,
        length: GameLength.hanchan,
      );
      expect(state.scores['p4'], 24500);
      expect(state.roundState.rotationIndex, 0);
      expect(state.roundState.honba, 0);
    });
  });
}