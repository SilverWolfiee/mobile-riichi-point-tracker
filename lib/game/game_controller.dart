import '../data/events_repository.dart';
import '../data/tables_repository.dart';
import '../scoring/game_event.dart';
import '../scoring/game_state.dart';
import '../scoring/round_state.dart';

class GameController {
  final EventsRepository eventsRepo;
  final TablesRepository tablesRepo;
  final String tableId;
  final List<String> playerIdsInSeatOrder;
  final int startingScore;
  final GameLength length;

  const GameController({
    required this.eventsRepo,
    required this.tablesRepo,
    required this.tableId,
    required this.playerIdsInSeatOrder,
    required this.startingScore,
    required this.length,
  });

  Future<GameState> loadState() => _reload();

  Future<GameState> _reload() async {
    final events = await eventsRepo.loadEvents(tableId);
    return applyEvents(
      events: events,
      playerIdsInSeatOrder: playerIdsInSeatOrder,
      startingScore: startingScore,
      length: length,
    );
  }

  Future<GameState> declareRiichi(String playerId) async {
    final current = await _reload();
    await eventsRepo.appendEvent(
      tableId: tableId,
      event: GameEvent(
        type: 'RIICHI_DECLARED',
        roundNumber: current.roundState.roundNumber,
        honba: current.roundState.honba,
        payload: {'playerId': playerId},
      ),
    );
    return _reload();
  }

  Future<GameState> recordWin({
    required String winnerId,
    required bool isTsumo,
    String? loserId,
    required int han,
    required int fu,
    List<String> yakuIds = const [],
  }) async {
    assert(isTsumo || loserId != null, 'loserId required for ron');
    final current = await _reload();
    await eventsRepo.appendEvent(
      tableId: tableId,
      event: GameEvent(
        type: 'WIN',
        roundNumber: current.roundState.roundNumber,
        honba: current.roundState.honba,
        payload: {
          'winnerId': winnerId,
          'isTsumo': isTsumo,
          if (!isTsumo) 'loserId': loserId,
          'han': han,
          'fu': fu,
          'yakuIds': yakuIds,
        },
      ),
    );
    return _reload();
  }

  Future<GameState> recordExhaustiveDraw(List<String> tenpaiPlayerIds) async {
    final current = await _reload();
    await eventsRepo.appendEvent(
      tableId: tableId,
      event: GameEvent(
        type: 'EXHAUSTIVE_DRAW',
        roundNumber: current.roundState.roundNumber,
        honba: current.roundState.honba,
        payload: {'tenpaiPlayerIds': tenpaiPlayerIds},
      ),
    );
    return _reload();
  }

  Future<GameState> adjustPoints({
    required String playerId,
    required int delta,
    String? reason,
  }) async {
    final current = await _reload();
    await eventsRepo.appendEvent(
      tableId: tableId,
      event: GameEvent(
        type: 'POINT_ADJUSTMENT',
        roundNumber: current.roundState.roundNumber,
        honba: current.roundState.honba,
        payload: {'playerId': playerId, 'delta': delta, 'reason': ?reason},
      ),
    );
    return _reload();
  }

  Future<GameState> forceEndGame() async {
    final current = await _reload();
    await eventsRepo.appendEvent(
      tableId: tableId,
      event: GameEvent(
        type: 'FORCE_END',
        roundNumber: current.roundState.roundNumber,
        honba: current.roundState.honba,
        payload: const {},
      ),
    );
    final finalState = await _reload();
    await tablesRepo.markFinished(tableId);
    return finalState;
  }
}
