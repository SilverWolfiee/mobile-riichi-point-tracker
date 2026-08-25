import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../theme/app_theme.dart';

class CreateTableScreen extends ConsumerStatefulWidget {
  const CreateTableScreen({super.key});

  @override
  ConsumerState<CreateTableScreen> createState() => _CreateTableScreenState();
}

class _CreateTableScreenState extends ConsumerState<CreateTableScreen> {
  String _length = 'hanchan';
  bool _tobiEnabled = true;
  bool _isSaving = false;

  final _eastController = TextEditingController();
  final _southController = TextEditingController();
  final _westController = TextEditingController();
  final _northController = TextEditingController();

  @override
  void dispose() {
    _eastController.dispose();
    _southController.dispose();
    _westController.dispose();
    _northController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _eastController.text.trim().isNotEmpty &&
      _southController.text.trim().isNotEmpty &&
      _westController.text.trim().isNotEmpty &&
      _northController.text.trim().isNotEmpty &&
      !_isSaving;

  Future<void> _submit() async {
    setState(() => _isSaving = true);

    final repo = ref.read(tablesRepositoryProvider);
    await repo.createTable(
      mode: 'yonma',
      length: _length,
      tobiEnabled: _tobiEnabled,
      seatedPlayers: [
        (seat: 'E', name: _eastController.text.trim()),
        (seat: 'S', name: _southController.text.trim()),
        (seat: 'W', name: _westController.text.trim()),
        (seat: 'N', name: _northController.text.trim()),
      ],
    );

    ref.invalidate(tablesListProvider);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Table')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _SectionLabel('Mode'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _ChoiceCard(
                  label: 'Yonma',
                  selected: true,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ChoiceCard(
                  label: 'Sanma (soon)',
                  selected: false,
                  enabled: false,
                  onTap: null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel('Length'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _ChoiceCard(
                  label: 'Tonpuusen',
                  selected: _length == 'tonpuu',
                  onTap: () => setState(() => _length = 'tonpuu'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ChoiceCard(
                  label: 'Hanchan',
                  selected: _length == 'hanchan',
                  onTap: () => setState(() => _length = 'hanchan'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.border),
            ),
            child: SwitchListTile(
              title: const Text('Tobi (bust) ends game',
                  style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Game ends immediately if a player goes negative',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              value: _tobiEnabled,
              activeThumbColor: AppColors.pinkAccent,
              onChanged: (v) => setState(() => _tobiEnabled = v),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel('Seating'),
          const SizedBox(height: AppSpacing.sm),
          _SeatField(label: 'East (Starting Dealer)', controller: _eastController, onChanged: () => setState(() {})),
          const SizedBox(height: AppSpacing.sm),
          _SeatField(label: 'South', controller: _southController, onChanged: () => setState(() {})),
          const SizedBox(height: AppSpacing.sm),
          _SeatField(label: 'West', controller: _westController, onChanged: () => setState(() {})),
          const SizedBox(height: AppSpacing.sm),
          _SeatField(label: 'North', controller: _northController, onChanged: () => setState(() {})),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: _canSubmit ? _submit : null,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                  )
                : const Text('Create Table'),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const _ChoiceCard({
    required this.label,
    required this.selected,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.pinkAccent : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: selected ? AppColors.pinkAccent : AppColors.border,
            ),
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
      ),
    );
  }
}

class _SeatField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _SeatField({required this.label, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.pinkAccent),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
    );
  }
}