import 'dart:math' as math;

import 'force_end_dialog.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/active_table_data.dart';
import '../data/database.dart';
import '../game/active_table_notifier.dart';
import '../scoring/round_state.dart';
import '../theme/app_theme.dart';
import 'win_dialog.dart';
import 'riichi_dialog.dart';
import 'draw_dialog.dart';

class ActiveTableScreen extends ConsumerWidget {
  final String tableId;
  const ActiveTableScreen({super.key, required this.tableId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(activeTableProvider(tableId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Table'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'End Game',
            onPressed: () => showForceEndDialog(
              context: context,
              ref: ref,
              tableId: tableId,
            ),
          ),
        ],
      ),
      body: asyncData.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.pinkPrimary),
        ),
        error: (err, _) => Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (data) {
          final gs = data.gameState;
          final dealerIndex = gs.roundState.dealerSeatIndex;

          // Standard seats order: E(0), S(1), W(2), N(3)
          final seatKeys = ['E', 'S', 'W', 'N'];

          // Dynamically map seats relative to dealer (dealer = bottom)
          // Dealer (East) -> Bottom (offset 0)
          // South -> Right (offset 1)
          // West -> Top (offset 2)
          // North -> Left (offset 3)
          Player playerAtOffset(int offset) {
            final targetIndex = (dealerIndex + offset) % 4;
            return data.playerAt(seatKeys[targetIndex]);
          }

          final bottomPlayer = playerAtOffset(0); // East / Dealer
          final rightPlayer = playerAtOffset(1);  // South
          final topPlayer = playerAtOffset(2);    // West
          final leftPlayer = playerAtOffset(3);   // North

          return Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Top Player (West relative to dealer / Toimen)
                        _RotatedSeatBox(
                          player: topPlayer,
                          score: gs.scores[topPlayer.id]!,
                          isDealer: false,
                          hasRiichi: gs.riichiDeclaredIds.contains(topPlayer.id),
                          angle: math.pi, // 180 deg
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Left Player (North relative to dealer / Kamicha)
                            _RotatedSeatBox(
                              player: leftPlayer,
                              score: gs.scores[leftPlayer.id]!,
                              isDealer: false,
                              hasRiichi: gs.riichiDeclaredIds.contains(leftPlayer.id),
                              angle: math.pi / 2, // 90 deg
                            ),
                            const SizedBox(width: AppSpacing.md),

                            // Center Board
                            _CenterBoardWithWinds(roundState: gs.roundState),

                            const SizedBox(width: AppSpacing.md),
                            // Right Player (South relative to dealer / Shimocha)
                            _RotatedSeatBox(
                              player: rightPlayer,
                              score: gs.scores[rightPlayer.id]!,
                              isDealer: false,
                              hasRiichi: gs.riichiDeclaredIds.contains(rightPlayer.id),
                              angle: -math.pi / 2, // -90 deg
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // Bottom Player (East / Dealer 👑)
                        _RotatedSeatBox(
                          player: bottomPlayer,
                          score: gs.scores[bottomPlayer.id]!,
                          isDealer: true,
                          hasRiichi: gs.riichiDeclaredIds.contains(bottomPlayer.id),
                          angle: 0, // 0 deg
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _ActionBar(tableId: tableId, data: data),
            ],
          );
        },
      ),
    );
  }
}

class _CenterBoardWithWinds extends StatelessWidget {
  final RoundState roundState;

  const _CenterBoardWithWinds({required this.roundState});

  String get _windLabel {
    switch (roundState.wind) {
      case Wind.east:
        return 'EAST';
      case Wind.south:
        return 'SOUTH';
      case Wind.west:
        return 'WEST';
      case Wind.north:
        return 'NORTH';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 130,
      decoration: BoxDecoration(
        color: AppColors.backgroundDeep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          // Top edge -> 西 (West)
          Positioned(
            top: 6,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                '西',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          // Bottom edge -> 東 (East - Dealer side)
          Positioned(
            bottom: 6,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                '東',
                style: TextStyle(
                  color: AppColors.pinkPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          // Left edge -> 北 (North)
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: const Center(
              child: Text(
                '北',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          // Right edge -> 南 (South)
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: const Center(
              child: Text(
                '南',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),

          // Main Center Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_windLabel ${roundState.roundNumber}',
                  style: const TextStyle(
                    color: AppColors.pinkPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '🀄 ${roundState.riichiSticksPot} pts',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '🔄 Honba: ${roundState.honba}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RotatedSeatBox extends StatelessWidget {
  final Player player;
  final int score;
  final bool isDealer;
  final bool hasRiichi;
  final double angle;

  const _RotatedSeatBox({
    required this.player,
    required this.score,
    required this.isDealer,
    required this.hasRiichi,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        constraints: const BoxConstraints(minWidth: 80, minHeight: 75),
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${player.name.toUpperCase()}${isDealer ? ' 👑' : ''}',
              style: TextStyle(
                color: isDealer ? AppColors.pinkPrimary : AppColors.textSecondary,
                fontWeight: isDealer ? FontWeight.w900 : FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$score',
              style: TextStyle(
                color: isDealer ? AppColors.pinkPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            if (hasRiichi) ...[
              const SizedBox(height: 6),
              const _StickIcon(),
            ],
          ],
        ),
      ),
    );
  }
}

class _StickIcon extends StatelessWidget {
  const _StickIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 4,
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(2)),
      alignment: Alignment.center,
      child: Container(
        width: 4,
        height: 4,
        decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  final String tableId;
  final ActiveTableData data;
  const _ActionBar({required this.tableId, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  onPressed: () => showRiichiDialog(
                    context: context,
                    ref: ref,
                    tableId: tableId,
                    data: data,
                  ),
                  child: const Text('Riichi'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pinkAccent,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  onPressed: () => showWinDialog(
                    context: context,
                    ref: ref,
                    tableId: tableId,
                    data: data,
                  ),
                  child: const Text('Win'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              onPressed: () => showDrawDialog(
                context: context,
                ref: ref,
                tableId: tableId,
                data: data,
              ),
              child: const Text('Exhaustive Draw'),
            ),
          ),
        ],
      ),
    );
  }
}