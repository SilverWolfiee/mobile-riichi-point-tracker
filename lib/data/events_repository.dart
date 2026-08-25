import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'database.dart';
import '../scoring/game_event.dart';

class EventsRepository {
  final AppDatabase db;
  const EventsRepository(this.db);

  static const _uuid = Uuid();

  Future<void> appendEvent({
    required String tableId,
    required GameEvent event,
  }) async {
    await db.into(db.events).insert(
      EventsCompanion.insert(
        id: _uuid.v4(),
        tableId: tableId,
        roundNumber: event.roundNumber,
        honba: event.honba,
        type: event.type,
        payload: jsonEncode(event.payload),
      ),
    );
  }

  Future<List<GameEvent>> loadEvents(String tableId) async {
    final query = db.select(db.events)
      ..where((e) => e.tableId.equals(tableId))
      ..orderBy([(e) => OrderingTerm(expression: e.createdAt)]);
    final rows = await query.get();
    return rows
        .map((row) => GameEvent(
              id: row.id,
              type: row.type,
              roundNumber: row.roundNumber,
              honba: row.honba,
              payload: jsonDecode(row.payload) as Map<String, dynamic>,
              createdAt: row.createdAt,
            ))
        .toList();
  }
}