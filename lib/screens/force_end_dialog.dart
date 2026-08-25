import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/active_table_notifier.dart';
import '../providers.dart';
import '../theme/app_theme.dart';

Future<void> showForceEndDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String tableId,
}) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      title: const Text('End game now?', style: TextStyle(color: AppColors.textPrimary)),
      content: const Text(
        'This finalizes the table with current scores. This cannot be undone.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () async {
            await ref.read(activeTableProvider(tableId).notifier).forceEndGame();
            ref.invalidate(tablesListProvider);
            if (context.mounted) {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            }
          },
          child: const Text('End Game', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );
}