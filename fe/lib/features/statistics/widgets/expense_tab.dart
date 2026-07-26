import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../activity/providers/transactions_provider.dart';
import '../../envelopes/models/envelope.dart';

class ExpenseTab extends StatelessWidget {
  final List<Transaction> expenseTx;
  final List<Envelope> envelopes;
  final ThemeData theme;
  final DateTime selectedDate;

  const ExpenseTab({
    super.key,
    required this.expenseTx,
    required this.envelopes,
    required this.theme,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    if (envelopes.isEmpty) {
      return const Center(child: Text('Belum ada data dompet.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDonutChart(),
          const SizedBox(height: 32),
          _buildEvaluasiMeteran(),
          const SizedBox(height: 32),
          _buildTopSpenders(),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildDonutChart() {
    final Map<String, double> expenseByPocket = {};
    for (var tx in expenseTx) {
      final pId = tx.pocketId;
      if (pId != null) {
        expenseByPocket[pId] = (expenseByPocket[pId] ?? 0) + tx.amount.abs();
      }
    }

    if (expenseByPocket.isEmpty) {
      return const Center(child: Text('Belum ada pengeluaran bulan ini.'));
    }

    // Sort descending
    final sortedEntries = expenseByPocket.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Colors mapping
    final colors = [
      AppColors.primary,
      AppColors.accentAmber,
      Colors.orange,
      Colors.teal,
      Colors.purple,
      Colors.pink,
      Colors.blue,
    ];

    double totalExpense = expenseByPocket.values.fold(
      0,
      (sum, val) => sum + val,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribusi Pengeluaran',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Berdasarkan pemakaian Saku / Dompet',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 75,
                  sections: sortedEntries.asMap().entries.map((e) {
                    final index = e.key;
                    final amt = e.value.value;
                    final pct = (amt / totalExpense) * 100;
                    return PieChartSectionData(
                      color: colors[index % colors.length],
                      value: amt,
                      title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
                      radius: 25,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total', style: theme.textTheme.labelSmall),
                  Text(
                    NumberFormat.currency(
                      locale: 'id',
                      symbol: 'Rp',
                      decimalDigits: 0,
                    ).format(totalExpense),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: sortedEntries.asMap().entries.map((e) {
            final index = e.key;
            final pId = e.value.key;

            // Cari nama saku
            String name = 'Lainnya';
            for (var env in envelopes) {
              if (env.id == pId) name = env.name;
              for (var p in env.pockets) {
                if (p.id == pId) name = p.name;
              }
            }

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(name, style: theme.textTheme.bodySmall),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEvaluasiMeteran() {
    final totalAllocation = envelopes.fold(
      0.0,
      (sum, e) => sum + e.allocatedAmount,
    );
    if (totalAllocation <= 0) return const SizedBox.shrink();

    // Petakan pengeluaran per envelope
    final Map<String, String> pocketIdToEnvelopeId = {};
    for (var env in envelopes) {
      pocketIdToEnvelopeId[env.id] = env.id;
      for (var p in env.pockets) {
        pocketIdToEnvelopeId[p.id] = env.id;
      }
    }

    final Map<String, double> envExpense = {};
    for (var tx in expenseTx) {
      if (tx.pocketId != null) {
        final envId = pocketIdToEnvelopeId[tx.pocketId!];
        if (envId != null) {
          envExpense[envId] = (envExpense[envId] ?? 0) + tx.amount.abs();
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evaluasi Proporsi (50/30/20)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...envelopes.map((env) {
          final targetPct = (env.allocatedAmount / totalAllocation) * 100;
          final expenseAmt = envExpense[env.id] ?? 0.0;
          final actualPct = (expenseAmt / totalAllocation) * 100;

          bool isOver = expenseAmt > env.allocatedAmount;
          Color barColor = isOver ? AppColors.error : Colors.green;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      env.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Target ${targetPct.toStringAsFixed(0)}% | Realita ${actualPct.toStringAsFixed(1)}% ${isOver ? '🔴' : '🟢'}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isOver ? AppColors.error : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (actualPct / 100).clamp(0.0, 1.0),
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTopSpenders() {
    final Map<String, double> pocketExpense = {};
    final Map<String, int> pocketCount = {};

    // Buat mapping pocketId ke nama (atau envelopeId jika tidak ada pocket)
    final Map<String, String> nameMap = {};
    for (var env in envelopes) {
      nameMap[env.id] = '${env.name} (Utama)';
      for (var p in env.pockets) {
        nameMap[p.id] = p.name;
      }
    }

    for (var tx in expenseTx) {
      final id = tx.pocketId;
      if (id != null) {
        pocketExpense[id] = (pocketExpense[id] ?? 0) + tx.amount.abs();
        pocketCount[id] = (pocketCount[id] ?? 0) + 1;
      }
    }

    final sortedEntries = pocketExpense.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top3 = sortedEntries.take(3).toList();

    if (top3.isEmpty) return const SizedBox.shrink();

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Spender (Kebocoran Terbesar)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...top3.map((entry) {
          final name = nameMap[entry.key] ?? 'Lainnya';
          final count = pocketCount[entry.key] ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        '$count kali transaksi',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  formatter.format(entry.value),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
