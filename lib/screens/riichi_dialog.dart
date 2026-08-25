import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/active_table_data.dart';
import '../game/active_table_notifier.dart';
import '../theme/app_theme.dart';

Future<void> showRiichiDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String tableId,
  required ActiveTableData data,
}) {
  return showDialog(
    context: context,
    builder: (context) => _RiichiDialog(tableId: tableId, data: data),
  );
}

class _RiichiDialog extends ConsumerWidget {
  final String tableId;
  final ActiveTableData data;
  const _RiichiDialog({required this.tableId, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gs = data.gameState;
    final eligible = data.playersInSeatOrder
        .where((p) => !gs.riichiDeclaredIds.contains(p.id))
        .toList();

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Who declared riichi?',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: eligible.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Text('Everyone has already declared riichi this round.',
                            style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          for (final p in eligible)
                            ListTile(
                              title: Text(p.name, style: const TextStyle(color: AppColors.textPrimary)),
                              trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                              onTap: () {
                                ref.read(activeTableProvider(tableId).notifier).declareRiichi(p.id);
                                Navigator.of(context).pop();
                              },
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}