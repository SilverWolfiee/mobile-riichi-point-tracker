import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riichi_tracker/screens/active_table_screen.dart';


import 'create_table_screen.dart';
import '../data/database.dart';
import '../providers.dart';
import '../theme/app_theme.dart';

class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _createTable() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CreateTableScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tablesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riichi Tracker'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.pinkAccent,
          labelColor: AppColors.pinkPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Finished'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTable,
        backgroundColor: AppColors.pinkAccent,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Table'),
      ),
      body: tablesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.pinkPrimary),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Failed to load tables: $err',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (tables) {
          final active = tables.where((t) => t.status == 'active').toList();
          final finished = tables.where((t) => t.status == 'finished').toList();
          return TabBarView(
            controller: _tabController,
            children: [
              _TableList(
                tables: active,
                emptyLabel: 'No active tables yet',
                onCreate: _createTable,
              ),
              _TableList(
                tables: finished,
                emptyLabel: 'No finished tables yet',
                onCreate: null,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TableList extends StatelessWidget {
  final List<GameTable> tables;
  final String emptyLabel;
  final VoidCallback? onCreate;

  const _TableList({
    required this.tables,
    required this.emptyLabel,
    this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    if (tables.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emptyLabel,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              if (onCreate != null) ...[
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pinkAccent,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                  ),
                  onPressed: onCreate,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 18),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        'New Table',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: tables.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final table = tables[index];
        return _TableCard(table: table);
      },
    );
  }
}
class _TableCard extends ConsumerWidget {
  final GameTable table;

  const _TableCard({required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: () => _confirmDelete(context, ref),
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: const BorderSide(color: AppColors.border),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          title: Text(
            '${table.mode.toUpperCase()} · ${table.length.toUpperCase()}',
            style: const TextStyle(
              color: AppColors.pinkPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            'Created ${_formatDate(table.createdAt)}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ActiveTableScreen(tableId: table.id),
              ),
            );
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Delete this table?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This permanently deletes the table and all its history.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(tablesRepositoryProvider).deleteTable(table.id);
              ref.invalidate(tablesListProvider);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
