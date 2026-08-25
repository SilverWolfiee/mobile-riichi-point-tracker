import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'database.g.dart';


@DataClassName('GameTable')
class Tables extends Table {
  TextColumn get id => text()();
  TextColumn get mode => text()(); // 'yonma' | 'sanma'
  TextColumn get length => text()(); // 'tonpuu' | 'hanchan'
  BoolColumn get tobiEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get status => text().withDefault(const Constant('active'))(); // 'active' | 'finished'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Players extends Table {
  TextColumn get id => text()();
  TextColumn get tableId => text().references(Tables, #id)();
  TextColumn get seat => text()(); // 'E' | 'S' | 'W' | 'N'
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}
@DataClassName('GameEventRow')
class Events extends Table {
  TextColumn get id => text()();
  TextColumn get tableId => text().references(Tables, #id)();
  IntColumn get roundNumber => integer()();
  IntColumn get honba => integer()();
  TextColumn get type => text()(); 
  TextColumn get payload => text()(); 
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}



@DriftDatabase(tables: [Tables, Players, Events])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'riichi_tracker.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}