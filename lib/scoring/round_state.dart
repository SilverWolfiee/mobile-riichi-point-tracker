enum Wind { east, south, west, north }

enum GameLength { tonpuu, hanchan }

class RoundState {
  final int rotationIndex;
  final int honba;
  final int riichiSticksPot;
  final bool finished;
  const RoundState({
    required this.rotationIndex,
    required this.honba,
    required this.riichiSticksPot,
    this.finished = false,
  });
  Wind get wind => Wind.values[rotationIndex ~/ 4];
  int get roundNumber => (rotationIndex % 4) + 1;
  int get dealerSeatIndex => rotationIndex % 4;
  RoundState copyWith({
    int? rotationIndex,
    int? honba,
    int? riichiSticksPot,
    bool? finished,
  }){
    return RoundState(
      rotationIndex: rotationIndex??this.rotationIndex,
      honba: honba??this.honba,
      riichiSticksPot: riichiSticksPot??this.riichiSticksPot,
      finished: finished??this.finished
    );
  }
}
int _lastRotationIndex(GameLength length) {
  return length == GameLength.tonpuu ? 3 : 7;
}

bool _needsOvertime({
  required List<int> scores,
  required int startingScore,
}) {
  return scores.every((s) => s <= startingScore);
}

RoundState resolveRoundEnd({
  required RoundState current,
  required GameLength length,
  required bool dealerWon,
  required bool isDraw,
  required bool dealerTenpai,
  required bool anyWin,
  required List<int> scoresAfterHand,
  required int startingScore,
  bool forceEnd = false,
}) {
  final dealerRepeats = dealerWon || (isDraw && dealerTenpai);
  final honbaIncrements = dealerWon || isDraw;

  final nextHonba = honbaIncrements ? current.honba + 1 : 0;
  final nextPot = anyWin ? 0 : current.riichiSticksPot;

  if (forceEnd) {
    return current.copyWith(
      honba: nextHonba,
      riichiSticksPot: nextPot,
      finished: true,
    );
  }

  if (dealerRepeats) {
    return current.copyWith(
      honba: nextHonba,
      riichiSticksPot: nextPot,
    );
  }

  final nextRotationIndex = current.rotationIndex + 1;
  final wasLastScheduledHand =
      current.rotationIndex == _lastRotationIndex(length);

  if (wasLastScheduledHand) {
    final overtime = _needsOvertime(
      scores: scoresAfterHand,
      startingScore: startingScore,
    );
    return RoundState(
      rotationIndex: nextRotationIndex,
      honba: nextHonba,
      riichiSticksPot: nextPot,
      finished: !overtime,
    );
  }

  return RoundState(
    rotationIndex: nextRotationIndex,
    honba: nextHonba,
    riichiSticksPot: nextPot,
  );
}