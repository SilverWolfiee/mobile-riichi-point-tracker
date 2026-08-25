import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../game/active_table_data.dart';
import '../game/active_table_notifier.dart';
import '../theme/app_theme.dart';

Future<void> showAdjustPointsDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String tableId,
  required ActiveTableData data,
}) {
  return showDialog(
    context: context,
    builder: (context) => _AdjustPointsDialog(tableId: tableId, data: data),
  );
}

class _AdjustPointsDialog extends ConsumerStatefulWidget {
  final String tableId;
  final ActiveTableData data;
  const _AdjustPointsDialog({required this.tableId, required this.data});

  @override
  ConsumerState<_AdjustPointsDialog> createState() => _AdjustPointsDialogState();
}

class _AdjustPointsDialogState extends ConsumerState<_AdjustPointsDialog> {
  Player? _player;
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  bool get _canConfirm =>
      _player != null && int.tryParse(_amountController.text.trim()) != null;

  void _confirm() {
    final delta = int.parse(_amountController.text.trim());
    final reason = _reasonController.text.trim();
    ref.read(activeTableProvider(widget.tableId).notifier).adjustPoints(
          playerId: _player!.id,
          delta: delta,
          reason: reason.isEmpty ? null : reason,
        );
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
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Point Adjustment',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: AppSpacing.md),
              _FieldLabel('Player'),
              const SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<Player>(
                initialValue: _player,
                dropdownColor: AppColors.surface,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                items: [
                  for (final p in players)
                    DropdownMenuItem(value: p, child: Text(p.name, style: const TextStyle(color: AppColors.textPrimary))),
                ],
                onChanged: (p) => setState(() => _player = p),
              ),
              const SizedBox(height: AppSpacing.md),
              _FieldLabel('Amount (use - for deduction)'),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                style: const TextStyle(color: AppColors.textPrimary),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'e.g. -500 or 500',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _FieldLabel('Reason (optional)'),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _reasonController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. chombo penalty',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
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
                      onPressed: _canConfirm ? _confirm : null,
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}