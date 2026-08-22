import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'database.dart';

class TablesRepository {
  final AppDatabase db;
  const TablesRepository(this.db);

  static const _uuid = Uuid();

  Future<String> createTable({
    required String mode,
    required String length,
    required bool tobiEnabled,
    required List<({String seat, String name})> seatedPlayers,
  }) async {
    final tableId = _uuid.v4();

    await db.into(db.tables).insert(
      TablesCompanion.insert(
        id: tableId,
        mode: mode,
        length: length,
        tobiEnabled: Value(tobiEnabled),
      ),
    );

    for (final p in seatedPlayers) {
      await db.into(db.players).insert(
        PlayersCompanion.insert(
          id: _uuid.v4(),
          tableId: tableId,
          seat: p.seat,
          name: p.name,
        ),
      );
    }

    return tableId;
  }

  Future<List<GameTable>> listTables() {
    return (db.select(db.tables)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<List<Player>> playersForTable(String tableId) {
    return (db.select(db.players)..where((p) => p.tableId.equals(tableId)))
        .get();
  }

  Future<void> markFinished(String tableId) {
    return (db.update(db.tables)..where((t) => t.id.equals(tableId)))
        .write(const TablesCompanion(status: Value('finished')));
  }
}