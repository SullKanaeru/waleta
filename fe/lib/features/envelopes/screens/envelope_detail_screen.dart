import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../activity/providers/transactions_provider.dart';
import '../models/envelope.dart';
import '../providers/envelope_provider.dart';
import '../widgets/create_pocket_sheet.dart';
import '../widgets/allocate_funds_sheet.dart';

class EnvelopeDetailScreen extends ConsumerWidget {
  final Envelope envelope;

  const EnvelopeDetailScreen({super.key, required this.envelope});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final envelopesAsync = ref.watch(envelopesProvider);
    final txsAsync = ref.watch(transactionsProvider);

    final envelopes = envelopesAsync.value ?? [];
    final allTxs = txsAsync.value ?? [];

    final currentEnv = envelopes.firstWhere(
      (e) => e.id == envelope.id,
      orElse: () => envelope,
    );

    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final totalPocketAllocated = currentEnv.pockets.fold(
      0.0,
      (sum, p) => sum + p.allocatedAmount,
    );
    final rawUnallocated = currentEnv.allocatedAmount - totalPocketAllocated;
    double totalNegativePockets = 0.0;
    for (var pocket in currentEnv.pockets) {
      if (pocket.allocatedAmount < 0) {
        totalNegativePockets += pocket.allocatedAmount.abs();
      }
    }
    final unallocated = rawUnallocated - totalNegativePockets;
    final displaySafeToSpend = currentEnv.safeToSpend(allTxs);

    return Scaffold(
      appBar: AppBar(title: Text(currentEnv.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(
            context,
            theme,
            formatter,
            displaySafeToSpend,
            currentEnv,
            unallocated,
            allTxs,
            envelopes,
          ),
          const SizedBox(height: 20),
          Text('Daftar Saku', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Alokasikan saldo ke saku pengeluaran',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          _buildPocketsList(
            context,
            ref,
            theme,
            formatter,
            currentEnv,
            unallocated,
            allTxs,
          ),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showCreatePocketSheet(context, currentEnv, unallocated),
        icon: const Icon(LucideIcons.plus, size: 18),
        label: const Text(
          'Buat Saku Baru',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: currentEnv.color,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showCreatePocketSheet(
    BuildContext context,
    Envelope env,
    double unallocated,
  ) {
    if (unallocated <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Saldo tidak cukup. Silakan isi saldo dompet terlebih dahulu.',
          ),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CreatePocketSheet(masterEnvelope: env, maxAllocatable: unallocated),
    );
  }

  void _showEditPocketSheet(
    BuildContext context,
    Envelope env,
    double unallocated,
    Pocket pocket,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePocketSheet(
        masterEnvelope: env,
        maxAllocatable: unallocated + pocket.allocatedAmount,
        existingPocket: pocket,
      ),
    );
  }

  void _confirmDeletePocket(
    BuildContext context,
    WidgetRef ref,
    Pocket pocket,
  ) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Saku Ini?'),
        content: Text(
          'Saku "${pocket.name}" akan dihapus dan sisa saldo (${formatter.format(pocket.allocatedAmount)}) akan kembali ke dana Belum Dialokasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(envelopesProvider.notifier)
                  .deletePocket(pocket.id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  int _getRemainingDays() {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final remaining = lastDay - now.day + 1;
    return remaining > 0 ? remaining : 1;
  }

  Widget _buildStsBanner(
    ThemeData theme,
    NumberFormat formatter,
    Pocket pocket,
    String masterId,
    int remainingDays,
    List<Transaction> allTxs,
  ) {
    Color color;
    IconData icon;
    String text;

    if (masterId == 'tabungan' || pocket.stsMode == StsMode.locked) {
      color = Colors.teal;
      icon = LucideIcons.lock;
      text = 'Dana Terkunci (Tabungan)';
    } else if (pocket.stsMode == StsMode.lumpSum) {
      color = Colors.purple;
      icon = LucideIcons.unlock;
      text = 'Bebas: ${formatter.format(pocket.allocatedAmount)}';
    } else if (pocket.stsMode == StsMode.customPeriod &&
        (pocket.stsPeriodDays ?? 0) > 0) {
      color = AppColors.warning;
      icon = LucideIcons.timer;
      final daily = pocket.calculateSts(masterId, remainingDays, allTxs);
      text =
          'STS: ${formatter.format(daily)} / hari (${pocket.stsPeriodDays} hari)';
    } else {
      color = AppColors.primary;
      icon = LucideIcons.shieldCheck;
      final daily = pocket.calculateSts(masterId, remainingDays, allTxs);
      text = 'Batas: ${formatter.format(daily)} / hari';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    NumberFormat formatter,
    double safeToSpend,
    Envelope env,
    double unallocated,
    List<Transaction> allTxs,
    List<Envelope> allEnvelopes,
  ) {
    final isTabungan =
        env.id == 'tabungan' || env.name.toLowerCase() == 'tabungan';

    // Calculate Emergency Runway
    int? runwayMonths;
    if (isTabungan) {
      final kebutuhanEnv = allEnvelopes.firstWhere(
        (e) => e.id == 'kebutuhan' || e.name.toLowerCase() == 'kebutuhan',
        orElse: () => env,
      );
      final kebutuhanPocketIds = kebutuhanEnv.pockets.map((p) => p.id).toSet();
      final kebutuhanTxs = allTxs
          .where(
            (t) =>
                t.pocketId != null &&
                kebutuhanPocketIds.contains(t.pocketId) &&
                t.amount < 0,
          )
          .toList();
      double totalKebutuhan = 0;
      for (var tx in kebutuhanTxs) {
        totalKebutuhan += tx.amount.abs();
      }

      // Calculate average (let's assume it's for 1 month for simplicity, or we can just use a fixed 30-day window)
      // Actually, better to get the total unique months we have data for, or default to 1
      if (totalKebutuhan > 0) {
        final uniqueMonths = kebutuhanTxs
            .map((t) => '${t.date.year}-${t.date.month}')
            .toSet()
            .length;
        final avgMonthly =
            totalKebutuhan / (uniqueMonths == 0 ? 1 : uniqueMonths);
        runwayMonths = (env.allocatedAmount / avgMonthly).floor();
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: env.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: env.color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: env.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(env.iconData, color: env.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saldo Dompet', style: theme.textTheme.labelSmall),
                    Text(
                      formatter.format(env.allocatedAmount),
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isTabungan && runwayMonths != null && runwayMonths > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.sparkles,
                    size: 14,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hebat! Tabungan ini bisa menghidupimu selama $runwayMonths Bulan jika kamu tiba-tiba kehilangan pendapatan.',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTabungan ? 'Status' : 'Safe-to-Spend',
                      style: theme.textTheme.labelSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isTabungan ? 'Terkunci' : formatter.format(safeToSpend),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: isTabungan ? Colors.teal : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Container(height: 24, width: 1, color: theme.dividerColor),
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AllocateFundsSheet(),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Belum Dialokasikan',
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatter.format(unallocated),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: unallocated > 0 ? AppColors.warning : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPocketsList(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    NumberFormat formatter,
    Envelope env,
    double unallocated,
    List<Transaction> allTxs,
  ) {
    final remainingDays = _getRemainingDays();
    if (env.pockets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text(
          'Belum ada saku. Buat saku baru di bawah.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }
    return Column(
      children: env.pockets.map((pocket) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: pocket.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(pocket.iconData, color: pocket.color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pocket.name,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          formatter.format(pocket.allocatedAmount),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        _showEditPocketSheet(context, env, unallocated, pocket),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        LucideIcons.edit2,
                        size: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _confirmDeletePocket(context, ref, pocket),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        LucideIcons.trash2,
                        size: 14,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildStsBanner(
                theme,
                formatter,
                pocket,
                env.id,
                remainingDays,
                allTxs,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
