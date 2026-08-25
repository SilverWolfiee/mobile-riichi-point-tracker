import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/active_table_data.dart';
import '../game/active_table_notifier.dart';
import '../theme/app_theme.dart';

Future<void> showDrawDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String tableId,
  required ActiveTableData data,
}) {
  return showDialog(
    context: context,
    builder: (context) => _DrawDialog(tableId: tableId, data: data),
  );
}

class _DrawDialog extends ConsumerStatefulWidget {
  final String tableId;
  final ActiveTableData data;
  const _DrawDialog({required this.tableId, required this.data});

  @override
  ConsumerState<_DrawDialog> createState() => _DrawDialogState();
}

class _DrawDialogState extends ConsumerState<_DrawDialog> {
  final Set<String> _tenpaiIds = {};

  void _confirm() {
    ref.read(activeTableProvider(widget.tableId).notifier)
        .recordExhaustiveDraw(_tenpaiIds.toList());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final players = widget.data.playersInSeatOrder;

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
              const Text('Exhaustive Draw',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: AppSpacing.xs),
              const Text('Select who is tenpai',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final p in players)
                      CheckboxListTile(
                        title: Text(p.name, style: const TextStyle(color: AppColors.textPrimary)),
                        value: _tenpaiIds.contains(p.id),
                        activeColor: AppColors.pinkAccent,
                        checkColor: AppColors.white,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _tenpaiIds.add(p.id);
                            } else {
                              _tenpaiIds.remove(p.id);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirm,
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}