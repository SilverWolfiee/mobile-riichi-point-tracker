import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/database.dart';
import 'data/events_repository.dart';
import 'data/tables_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final tablesRepositoryProvider = Provider<TablesRepository>((ref) {
  return TablesRepository(ref.watch(appDatabaseProvider));
});

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepository(ref.watch(appDatabaseProvider));
});

final tablesListProvider = FutureProvider<List<GameTable>>((ref) {
  return ref.watch(tablesRepositoryProvider).listTables();
});