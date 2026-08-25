import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../scoring/round_state.dart';
import 'active_table_data.dart';
import 'game_controller.dart';

const _seatOrder = ['E', 'S', 'W', 'N'];

class ActiveTableNotifier extends FamilyAsyncNotifier<ActiveTableData, String> {
  @override
  Future<ActiveTableData> build(String tableId) async {
    final tablesRepo = ref.read(tablesRepositoryProvider);
    final eventsRepo = ref.read(eventsRepositoryProvider);

    final table = await tablesRepo.getTable(tableId);
    if (table == null) {
      throw StateError('Table $tableId not found');
    }

    final players = await tablesRepo.playersForTable(tableId);
    final sortedPlayers = [
      for (final seat in _seatOrder)
        players.firstWhere((p) => p.seat == seat),
    ];

    final controller = GameController(
      eventsRepo: eventsRepo,
      tablesRepo: tablesRepo,
      tableId: tableId,
      playerIdsInSeatOrder: sortedPlayers.map((p) => p.id).toList(),
      startingScore: 25000,
      length: table.length == 'tonpuu' ? GameLength.tonpuu : GameLength.hanchan,
    );

    final gameState = await controller.loadState();

    return ActiveTableData(
      table: table,
      playersInSeatOrder: sortedPlayers,
      gameState: gameState,
      controller: controller,
    );
  }

  Future<void> declareRiichi(String playerId) async {
    final current = state.value;
    if (current == null) return;
    final newState = await current.controller.declareRiichi(playerId);
    state = AsyncData(current.copyWith(gameState: newState));
  }

  Future<void> recordWin({
    required String winnerId,
    required bool isTsumo,
    String? loserId,
    required int han,
    required int fu,
    List<String> yakuIds = const [],
  }) async {
    final current = state.value;
    if (current == null) return;
    final newState = await current.controller.recordWin(
      winnerId: winnerId,
      isTsumo: isTsumo,
      loserId: loserId,
      han: han,
      fu: fu,
      yakuIds: yakuIds,
    );
    state = AsyncData(current.copyWith(gameState: newState));
  }

  Future<void> recordExhaustiveDraw(List<String> tenpaiPlayerIds) async {
    final current = state.value;
    if (current == null) return;
    final newState = await current.controller.recordExhaustiveDraw(tenpaiPlayerIds);
    state = AsyncData(current.copyWith(gameState: newState));
  }

  Future<void> adjustPoints({
    required String playerId,
    required int delta,
    String? reason,
  }) async {
    final current = state.value;
    if (current == null) return;
    final newState = await current.controller.adjustPoints(
      playerId: playerId,
      delta: delta,
      reason: reason,
    );
    state = AsyncData(current.copyWith(gameState: newState));
  }

  Future<void> forceEndGame() async {
    final current = state.value;
    if (current == null) return;
    final newState = await current.controller.forceEndGame();
    state = AsyncData(current.copyWith(gameState: newState));
  }
}

final activeTableProvider =
    AsyncNotifierProvider.family<ActiveTableNotifier, ActiveTableData, String>(
  ActiveTableNotifier.new,
);