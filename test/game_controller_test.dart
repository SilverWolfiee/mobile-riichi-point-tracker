import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:riichi_tracker/data/database.dart';
import 'package:riichi_tracker/data/events_repository.dart';
import 'package:riichi_tracker/data/tables_repository.dart';
import 'package:riichi_tracker/game/game_controller.dart';
import 'package:riichi_tracker/scoring/round_state.dart';

void main() {
  late AppDatabase db;
  late TablesRepository tablesRepo;
  late EventsRepository eventsRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    tablesRepo = TablesRepository(db);
    eventsRepo = EventsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<GameController> makeController() async {
    final created = await tablesRepo.createTable(
      mode: 'yonma',
      length: 'hanchan',
      tobiEnabled: true,
      seatedPlayers: const [
        (seat: 'E', name: 'Rycene'),
        (seat: 'S', name: 'P2'),
        (seat: 'W', name: 'P3'),
        (seat: 'N', name: 'P4'),
      ],
    );

    return GameController(
      eventsRepo: eventsRepo,
      tablesRepo: tablesRepo,
      tableId: created.tableId,
      playerIdsInSeatOrder: created.playerIds,
      startingScore: 25000,
      length: GameLength.hanchan,
    );
  }

  test('fresh table starts at East 1 with everyone at starting score', () async {
    final controller = await makeController();
    final state = await controller.loadState();

    expect(state.roundState.rotationIndex, 0);
    expect(state.scores.values.every((s) => s == 25000), true);
  });

  test('riichi persists across reload', () async {
    final controller = await makeController();
    final playerId = controller.playerIdsInSeatOrder[1];

    await controller.declareRiichi(playerId);
    final reloaded = await controller.loadState();

    expect(reloaded.scores[playerId], 24000);
    expect(reloaded.roundState.riichiSticksPot, 1000);
  });

  test('dealer win persists and repeats dealer with honba+1', () async {
    final controller = await makeController();
    final dealerId = controller.playerIdsInSeatOrder[0];

    await controller.recordWin(winnerId: dealerId, isTsumo: true, han: 4, fu: 30);
    final state = await controller.loadState();

    expect(state.roundState.rotationIndex, 0);
    expect(state.roundState.honba, 1);
    expect(state.scores[dealerId]! > 25000, true);
  });

  test('multiple events replay in correct order', () async {
    final controller = await makeController();
    final p2 = controller.playerIdsInSeatOrder[1];
    final p3 = controller.playerIdsInSeatOrder[2];

    await controller.declareRiichi(p2);
    await controller.recordWin(
      winnerId: p3,
      isTsumo: false,
      loserId: p2,
      han: 3,
      fu: 30,
    );
    final state = await controller.loadState();

    // riichi: p2 -1000, pot +1000; ron: base=960, roundUp(960*4)=3900
    expect(state.scores[p2], 25000 - 1000 - 3900);
    expect(state.scores[p3], 25000 + 3900 + 1000);
    expect(state.roundState.riichiSticksPot, 0);
  });

  test('exhaustive draw persists and advances round when dealer noten', () async {
    final controller = await makeController();
    final p2 = controller.playerIdsInSeatOrder[1];

    await controller.recordExhaustiveDraw([p2]);
    final state = await controller.loadState();

    expect(state.roundState.rotationIndex, 1);
    expect(state.roundState.honba, 1);
  });

  test('point adjustment persists independently of round state', () async {
    final controller = await makeController();
    final p4 = controller.playerIdsInSeatOrder[3];

    await controller.adjustPoints(playerId: p4, delta: -500, reason: 'penalty');
    final state = await controller.loadState();

    expect(state.scores[p4], 24500);
  });

  test('forceEndGame marks table finished and persists final state', () async {
    final controller = await makeController();
    final dealerId = controller.playerIdsInSeatOrder[0];

    await controller.recordWin(winnerId: dealerId, isTsumo: true, han: 2, fu: 30);
    final finalState = await controller.forceEndGame();

    expect(finalState.roundState.finished, true);

    final tables = await tablesRepo.listTables();
    expect(tables.first.status, 'finished');
  });

  test('multiple tables are independent', () async {
    final controllerA = await makeController();
    final controllerB = await makeController();

    final p1A = controllerA.playerIdsInSeatOrder[0];
    await controllerA.declareRiichi(p1A);

    final stateA = await controllerA.loadState();
    final stateB = await controllerB.loadState();

    expect(stateA.roundState.riichiSticksPot, 1000);
    expect(stateB.roundState.riichiSticksPot, 0);
  });
}