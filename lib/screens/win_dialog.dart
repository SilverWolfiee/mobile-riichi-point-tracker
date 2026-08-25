import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../game/active_table_data.dart';
import '../game/active_table_notifier.dart';
import '../scoring/yaku.dart';
import '../theme/app_theme.dart';

Future<void> showWinDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String tableId,
  required ActiveTableData data,
}) {
  return showDialog(
    context: context,
    builder: (context) => _WinDialog(tableId: tableId, data: data),
  );
}

class _WinDialog extends ConsumerStatefulWidget {
  final String tableId;
  final ActiveTableData data;
  const _WinDialog({required this.tableId, required this.data});

  @override
  ConsumerState<_WinDialog> createState() => _WinDialogState();
}

class _WinDialogState extends ConsumerState<_WinDialog> {
  bool _isTsumo = true;
  Player? _winner;
  Player? _loser;
  final Set<String> _selectedYakuIds = {};
  final _fuController = TextEditingController(text: '30');

  @override
  void dispose() {
    _fuController.dispose();
    super.dispose();
  }

  /// Check if Chiitoitsu (Seven Pairs) is selected
  bool get _isChiitoitsuSelected {
    return _selectedYakuIds.any((id) {
      final y = allYaku.firstWhere((element) => element.id == id, orElse: () => allYaku.first);
      return y.id == 'chiitoitsu' || y.name.toLowerCase().contains('chiitoi') || y.name.toLowerCase().contains('seven pairs');
    });
  }

  /// Helper to check if winner has declared Riichi
  bool get _winnerHasRiichi {
    if (_winner == null) return false;
    return widget.data.gameState.riichiDeclaredIds.contains(_winner!.id);
  }

  int get _totalHan => _selectedYakuIds.fold(
        0,
        (sum, id) => sum + allYaku.firstWhere((y) => y.id == id).han,
      );

  bool get _fuLocked => _totalHan >= 5 || _isChiitoitsuSelected;

  bool get _canConfirm =>
      _winner != null &&
      (_isTsumo || _loser != null) &&
      _selectedYakuIds.isNotEmpty;

  void _sanitizeSelectedYaku() {
    // If Ron selected, remove Menzen Tsumo
    if (!_isTsumo) {
      _selectedYakuIds.removeWhere((id) {
        final y = allYaku.firstWhere((element) => element.id == id, orElse: () => allYaku.first);
        return y.id == 'menzen_tsumo' || y.name.toLowerCase().contains('tsumo');
      });
    }

    // If winner has not declared Riichi, remove Riichi, Double Riichi, and Ippatsu
    if (!_winnerHasRiichi) {
      _selectedYakuIds.removeWhere((id) {
        final y = allYaku.firstWhere((element) => element.id == id, orElse: () => allYaku.first);
        final name = y.name.toLowerCase();
        return y.id == 'riichi' || y.id == 'double_riichi' || y.id == 'ippatsu' || name.contains('riichi') || name.contains('ippatsu');
      });
    }

    // Lock Fu to 25 if Chiitoitsu is selected
    if (_isChiitoitsuSelected) {
      _fuController.text = '25';
    }
  }

  Future<void> _addYaku() async {
    final picked = await showDialog<YakuEntry>(
      context: context,
      builder: (context) => _YakuPickerDialog(
        alreadySelected: _selectedYakuIds,
        isTsumo: _isTsumo,
        hasDeclaredRiichi: _winnerHasRiichi,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedYakuIds.add(picked.id);
        _sanitizeSelectedYaku();
      });
    }
  }

  void _confirm() {
    final int fu = _isChiitoitsuSelected
        ? 25
        : (_totalHan >= 5 ? 0 : int.tryParse(_fuController.text.trim()) ?? 30);

    ref.read(activeTableProvider(widget.tableId).notifier).recordWin(
          winnerId: _winner!.id,
          isTsumo: _isTsumo,
          loserId: _isTsumo ? null : _loser!.id,
          han: _totalHan,
          fu: fu,
          yakuIds: _selectedYakuIds.toList(),
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
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Record Win',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _ChoiceCard(
                      label: 'Tsumo',
                      selected: _isTsumo,
                      onTap: () => setState(() {
                        _isTsumo = true;
                        _loser = null;
                        _sanitizeSelectedYaku();
                      }),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ChoiceCard(
                      label: 'Ron',
                      selected: !_isTsumo,
                      onTap: () => setState(() {
                        _isTsumo = false;
                        _sanitizeSelectedYaku();
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Winner'),
                      _PlayerDropdown(
                        players: players,
                        value: _winner,
                        onChanged: (p) => setState(() {
                          _winner = p;
                          _sanitizeSelectedYaku();
                        }),
                      ),
                      if (!_isTsumo) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _FieldLabel('Loser (discarder)'),
                        _PlayerDropdown(
                          players: players.where((p) => p != _winner).toList(),
                          value: _loser,
                          onChanged: (p) => setState(() => _loser = p),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _FieldLabel('Yaku'),
                          Text(
                            '$_totalHan han',
                            style: const TextStyle(
                              color: AppColors.pinkPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final id in _selectedYakuIds)
                            Chip(
                              label: Text(allYaku.firstWhere((y) => y.id == id).name),
                              labelStyle: const TextStyle(color: AppColors.white, fontSize: 12),
                              backgroundColor: AppColors.pinkStrong,
                              deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.white),
                              onDeleted: () => setState(() {
                                _selectedYakuIds.remove(id);
                                if (!_isChiitoitsuSelected && _fuController.text == '25') {
                                  _fuController.text = '30';
                                }
                              }),
                            ),
                          ActionChip(
                            label: const Text('+ Add Yaku'),
                            labelStyle: const TextStyle(color: AppColors.pinkPrimary, fontSize: 12),
                            backgroundColor: AppColors.background,
                            side: const BorderSide(color: AppColors.border),
                            onPressed: _winner == null ? null : _addYaku,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _FieldLabel('Fu'),
                      const SizedBox(height: AppSpacing.xs),
                      _fuLocked
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(AppRadii.md),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                _isChiitoitsuSelected
                                    ? 'Fixed to 25 Fu (Chiitoitsu)'
                                    : 'Irrelevant at 5+ han',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                            )
                          : TextField(
                              controller: _fuController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadii.md),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                              ),
                            ),
                    ],
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

class _YakuPickerDialog extends StatefulWidget {
  final Set<String> alreadySelected;
  final bool isTsumo;
  final bool hasDeclaredRiichi;

  const _YakuPickerDialog({
    required this.alreadySelected,
    required this.isTsumo,
    required this.hasDeclaredRiichi,
  });

  @override
  State<_YakuPickerDialog> createState() => _YakuPickerDialogState();
}

class _YakuPickerDialogState extends State<_YakuPickerDialog> {
  String _filter = 'all';

  List<String> get _filterOptions {
    final hans = allYaku
        .where((y) => y.special == YakuSpecial.none)
        .map((y) => y.han)
        .toSet()
        .toList()
      ..sort();
    return ['all', ...hans.map((h) => h.toString()), 'nagashi', 'yakuman', 'double_yakuman'];
  }

  List<YakuEntry> get _filtered {
    // 1. Exclude already selected
    var available = allYaku.where((y) => !widget.alreadySelected.contains(y.id));

    // 2. Filter out Menzen Tsumo on Ron
    if (!widget.isTsumo) {
      available = available.where((y) => y.id != 'menzen_tsumo' && !y.name.toLowerCase().contains('tsumo'));
    }

    // 3. Filter out Riichi / Double Riichi / Ippatsu if not declared
    if (!widget.hasDeclaredRiichi) {
      available = available.where((y) {
        final name = y.name.toLowerCase();
        return y.id != 'riichi' && y.id != 'double_riichi' && y.id != 'ippatsu' && !name.contains('riichi') && !name.contains('ippatsu');
      });
    }

    switch (_filter) {
      case 'all':
        return available.toList();
      case 'nagashi':
        return available.where((y) => y.special == YakuSpecial.nagashiMangan).toList();
      case 'yakuman':
        return available.where((y) => y.special == YakuSpecial.yakuman).toList();
      case 'double_yakuman':
        return available.where((y) => y.special == YakuSpecial.doubleYakuman).toList();
      default:
        final han = int.tryParse(_filter);
        return available.where((y) => y.special == YakuSpecial.none && y.han == han).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Yaku',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final f in _filterOptions)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: ChoiceChip(
                          label: Text(_filterLabel(f)),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                          selectedColor: AppColors.pinkAccent,
                          backgroundColor: AppColors.background,
                          labelStyle: TextStyle(
                            color: _filter == f ? AppColors.white : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView(
                  children: [
                    for (final y in _filtered)
                      ListTile(
                        title: Text(y.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                        subtitle: y.closedOnly
                            ? const Text('Closed hand only',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 11))
                            : null,
                        trailing: Text('${y.han}han',
                            style: const TextStyle(color: AppColors.pinkPrimary, fontWeight: FontWeight.w800)),
                        onTap: () => Navigator.of(context).pop(y),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _filterLabel(String f) {
    switch (f) {
      case 'all': return 'All';
      case 'nagashi': return 'Nagashi';
      case 'yakuman': return 'Yakuman';
      case 'double_yakuman': return '2x Yakuman';
      default: return '$f han';
    }
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700),
    );
  }
}

class _PlayerDropdown extends StatelessWidget {
  final List<Player> players;
  final Player? value;
  final ValueChanged<Player?> onChanged;

  const _PlayerDropdown({required this.players, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Player>(
      initialValue: value,
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
      onChanged: onChanged,
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCard({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.pinkAccent : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: selected ? AppColors.pinkAccent : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}