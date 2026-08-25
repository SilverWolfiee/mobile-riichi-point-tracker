import '../data/database.dart';
import '../scoring/game_state.dart';

import 'game_controller.dart';

class ActiveTableData {
  final GameTable table;
  final List<Player> playersInSeatOrder;
  final GameState gameState;
  final GameController controller;
  const ActiveTableData({
    required this.table,
    required this.playersInSeatOrder,
    required this.gameState,
    required this.controller,
  });
  ActiveTableData copyWith({GameState? gameState}) {
    return ActiveTableData(
      table: table,
      playersInSeatOrder: playersInSeatOrder,
      gameState: gameState ?? this.gameState,
      controller: controller,
    );
  }

  Player playerAt(String seat) =>
      playersInSeatOrder.firstWhere((p) => p.seat == seat);
}
