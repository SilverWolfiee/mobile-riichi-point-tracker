import 'package:flutter/material.dart';
import 'data/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();

  final tableId = 'test-table-1';
  await db.into(db.tables).insert(
    TablesCompanion.insert(
      id: tableId,
      mode: 'yonma',
      length: 'hanchan',
    ),
  );

  await db.into(db.players).insert(
    PlayersCompanion.insert(
      id: 'p1',
      tableId: tableId,
      seat: 'E',
      name: 'Rycene',
    ),
  );

  final tables = await db.select(db.tables).get();
  final players = await db.select(db.players).get();

  print('Tables: $tables');
  print('Players: $players');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Riichi Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('DB smoke test ran — check the debug console'),
        ),
      ),
    );
  }
}