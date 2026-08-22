class GameEvent {
  final String? id;
  final String type;
  final int roundNumber;
  final int honba;
  final Map<String, dynamic> payload;
  final DateTime? createdAt;

  const GameEvent({
    this.id,
    required this.type,
    required this.roundNumber,
    required this.honba,
    required this.payload,
    this.createdAt,
  });
}