import 'package:flutter_test/flutter_test.dart';
import 'package:riichi_tracker/scoring/round_state.dart';

void main() {
  group('RoundState derived getters', () {
    test('rotationIndex 0 is East 1, dealer seat 0', () {
      const state = RoundState(rotationIndex: 0, honba: 0, riichiSticksPot: 0);
      expect(state.wind, Wind.east);
      expect(state.roundNumber, 1);
      expect(state.dealerSeatIndex, 0);
    });

    test('rotationIndex 4 is South 1, dealer seat 0', () {
      const state = RoundState(rotationIndex: 4, honba: 0, riichiSticksPot: 0);
      expect(state.wind, Wind.south);
      expect(state.roundNumber, 1);
      expect(state.dealerSeatIndex, 0);
    });

    test('rotationIndex 6 is South 3, dealer seat 2', () {
      const state = RoundState(rotationIndex: 6, honba: 0, riichiSticksPot: 0);
      expect(state.wind, Wind.south);
      expect(state.roundNumber, 3);
      expect(state.dealerSeatIndex, 2);
    });
  });

  group('resolveRoundEnd dealer repeat logic', () {
    test('dealer win repeats with honba+1', () {
      const current = RoundState(rotationIndex: 0, honba: 0, riichiSticksPot: 0);
      final next = resolveRoundEnd(
        current: current,
        length: GameLength.hanchan,
        dealerWon: true,
        isDraw: false,
        dealerTenpai: false,
        anyWin: true,
        scoresAfterHand: [26000, 24000, 25000, 25000],
        startingScore: 25000,
      );
      expect(next.rotationIndex, 0);
      expect(next.honba, 1);
      expect(next.riichiSticksPot, 0);
    });

    test('draw with dealer tenpai repeats, honba increments', () {
      const current = RoundState(rotationIndex: 0, honba: 1, riichiSticksPot: 0);
      final next = resolveRoundEnd(
        current: current,
        length: GameLength.hanchan,
        dealerWon: false,
        isDraw: true,
        dealerTenpai: true,
        anyWin: false,
        scoresAfterHand: [25000, 25000, 25000, 25000],
        startingScore: 25000,
      );
      expect(next.rotationIndex, 0);
      expect(next.honba, 2);
    });

    test('draw with dealer noten rotates, honba still increments', () {
      const current = RoundState(rotationIndex: 0, honba: 0, riichiSticksPot: 0);
      final next = resolveRoundEnd(
        current: current,
        length: GameLength.hanchan,
        dealerWon: false,
        isDraw: true,
        dealerTenpai: false,
        anyWin: false,
        scoresAfterHand: [25000, 25000, 25000, 25000],
        startingScore: 25000,
      );
      expect(next.rotationIndex, 1);
      expect(next.honba, 1);
    });

    test('non-dealer win rotates and resets honba', () {
      const current = RoundState(rotationIndex: 3, honba: 2, riichiSticksPot: 0);
      final next = resolveRoundEnd(
        current: current,
        length: GameLength.hanchan,
        dealerWon: false,
        isDraw: false,
        dealerTenpai: false,
        anyWin: true,
        scoresAfterHand: [24000, 26000, 25000, 25000],
        startingScore: 25000,
      );
      expect(next.rotationIndex, 4);
      expect(next.honba, 0);
    });

    test('any win clears riichi stick pot', () {
      const current = RoundState(rotationIndex: 0, honba: 0, riichiSticksPot: 2000);
      final next = resolveRoundEnd(
        current: current,
        length: GameLength.hanchan,
        dealerWon: true,
        isDraw: false,
        dealerTenpai: false,
        anyWin: true,
        scoresAfterHand: [27000, 24000, 25000, 25000],
        startingScore: 25000,
      );
      expect(next.riichiSticksPot, 0);
    });

    test('draw with no win keeps riichi stick pot', () {
      const current = RoundState(rotationIndex: 0, honba: 0, riichiSticksPot: 1000);
      final next = resolveRoundEnd(
        current: current,
        length: GameLength.hanchan,
        dealerWon: false,
        isDraw: true,
        dealerTenpai: true,
        anyWin: false,
        scoresAfterHand: [25000, 25000, 25000, 25000],
        startingScore: 25000,
      );
      expect(next.riichiSticksPot, 1000);
    });
  });

  group('resolveRoundEnd game ending', () {
    test('tonpuu ends after East 4 if someone is above starting score', () {
      const current = RoundState(rotationIndex: 3, honba: 0, riichiSticksPot: 0);
      final next = resolveRoundEnd(
        current: current,
        length: GameLength.tonpuu,
        dealerWon: false,
        isDraw: false,
        dealerTenpai: false,
        anyWin: true,
        scoresAfterHand: [30000, 20000, 25000, 25000],
        startingScore: 25000,
      );
      expect(next.finished, true);
    });

    test('hanchan goes to overtime if everyone still at/below starting score after South 4', () {
      const current = RoundState(rotationIndex: 7, honba: 0, riichiSticksPot: 0);
      final next = resolveRoundEnd(
        current: current,
        length: GameLength.hanchan,
        dealerWon: false,
        isDraw: false,
        dealerTenpai: false,
        anyWin: true,
        scoresAfterHand: [25000, 25000, 25000, 25000],
        startingScore: 25000,
      );
      expect(next.finished, false);
      expect(next.rotationIndex, 8);
    });

    test('hanchan ends at South 4 if someone is above starting score', () {
      const current = RoundState(rotationIndex: 7, honba: 0, riichiSticksPot: 0);
      final next = resolveRoundEnd(
        current: current,
        length: GameLength.hanchan,
        dealerWon: false,
        isDraw: false,
        dealerTenpai: false,
        anyWin: true,
        scoresAfterHand: [26000, 24000, 25000, 25000],
        startingScore: 25000,
      );
      expect(next.finished, true);
    });

    test('forceEnd overrides everything', () {
      const current = RoundState(rotationIndex: 0, honba: 3, riichiSticksPot: 1000);
      final next = resolveRoundEnd(
        current: current,
        length: GameLength.hanchan,
        dealerWon: true,
        isDraw: false,
        dealerTenpai: false,
        anyWin: true,
        scoresAfterHand: [25000, 25000, 25000, 25000],
        startingScore: 25000,
        forceEnd: true,
      );
      expect(next.finished, true);
      expect(next.rotationIndex, 0);
    });
  });
}