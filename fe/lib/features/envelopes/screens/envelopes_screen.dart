import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/envelope_provider.dart';
import '../models/envelope.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../activity/providers/transactions_provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../widgets/allocate_funds_sheet.dart';

class EnvelopesScreen extends ConsumerWidget {
  const EnvelopesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final envelopesAsync = ref.watch(envelopesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final txsAsync = ref.watch(transactionsProvider);

    final accounts = accountsAsync.value ?? [];
    final allTxs = txsAsync.value ?? [];
    final envelopes = envelopesAsync.value ?? [];

    final totalRealBalance = accounts.fold(
      0.0,
      (sum, acc) => sum + acc.balance,
    );

    final totalAllocated = envelopes.fold(
      0.0,
      (sum, env) => sum + env.allocatedAmount,
    );
    final unallocatedBalance = totalRealBalance - totalAllocated;

    // Hitung total hutang dari pocket yang bersaldo minus
    double totalNegativePockets = 0.0;
    for (var env in envelopes) {
      for (var pocket in env.pockets) {
        if (pocket.allocatedAmount < 0) {
          totalNegativePockets += pocket.allocatedAmount.abs();
        }
      }
    }
    final netUnallocatedBalance = unallocatedBalance - totalNegativePockets;

    double totalSts = envelopes.fold(
      0.0,
      (sum, env) => sum + env.safeToSpend(allTxs),
    );
    if (netUnallocatedBalance < 0) {
      totalSts = (totalSts + netUnallocatedBalance).clamp(0.0, double.infinity);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dompet'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.arrowUpRight, size: 20),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AllocateFundsSheet(),
              );
            },
          ),
        ],
      ),
      body: envelopesAsync.when(
        loading: () => Skeletonizer(
          enabled: true,
          child: _buildMasterContent(
            context,
            ref,
            theme,
            [
              Envelope(
                id: 'skel_1',
                name: 'Kebutuhan Pokok',
                allocatedAmount: 1500000,
                iconData: LucideIcons.shoppingBag,
                color: Colors.blue,
                pockets: [],
                sources: {},
              ),
              Envelope(
                id: 'skel_2',
                name: 'Keinginan',
                allocatedAmount: 500000,
                iconData: LucideIcons.coffee,
                color: Colors.orange,
                pockets: [],
                sources: {},
              ),
            ],
            allTxs,
            totalRealBalance: 15000000,
            unallocatedBalance: 2500000,
            totalSts: 3500000,
          ),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (envelopesList) => _buildMasterContent(
          context,
          ref,
          theme,
          envelopesList,
          allTxs,
          totalRealBalance: totalRealBalance,
          unallocatedBalance: netUnallocatedBalance, // Gunakan net
          totalSts: totalSts,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AllocateFundsSheet(),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(LucideIcons.arrowUpRight, size: 20),
      ),
    );
  }

  Widget _buildMasterContent(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    List<Envelope> envelopes,
    List<Transaction> allTxs, {
    required double totalRealBalance,
    required double unallocatedBalance,
    required double totalSts,
  }) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final unallocatedDisplay = unallocatedBalance;

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(accountsProvider.notifier).refresh();
        ref.read(dashboardProvider.notifier).refresh();
        ref.read(envelopesProvider.notifier).refresh();
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
      children: [
        // Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Saldo',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatter.format(totalRealBalance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Safe-to-Spend Harian',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatter.format(totalSts),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Container(height: 24, width: 1, color: Colors.white24),
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
                                const Text(
                                  'Belum Dialokasikan',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatter.format(unallocatedDisplay),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
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
        ),
        const SizedBox(height: 24),
        Text('Dompet', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),

        ...envelopes.map(
          (env) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMasterCard(context, env, formatter, theme, allTxs),
          ),
        ),
        const SizedBox(height: 48),
      ],
    ),
    );
  }

  Widget _buildMasterCard(
    BuildContext context,
    Envelope env,
    NumberFormat formatter,
    ThemeData theme,
    List<Transaction> allTxs,
  ) {
    return GestureDetector(
      onTap: () {
        context.push('/envelope/${env.id}', extra: env);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
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
                  child: Text(
                    env.name,
                    style: theme.textTheme.titleSmall?.copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: theme.disabledColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saldo', style: theme.textTheme.labelSmall),
                    const SizedBox(height: 2),
                    Text(
                      formatter.format(env.allocatedAmount),
                      style: theme.textTheme.titleSmall?.copyWith(fontSize: 15),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.shieldCheck,
                          size: 12,
                          color: env.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Safe-to-Spend',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: env.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    _buildStsDisplay(env, formatter, theme, allTxs),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStsDisplay(
    Envelope env,
    NumberFormat formatter,
    ThemeData theme,
    List<Transaction> allTxs,
  ) {
    if (env.id == 'tabungan' || env.stsMode == StsMode.locked) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.lock, size: 12, color: Colors.teal),
          const SizedBox(width: 4),
          Text('Ditabung', style: TextStyle(color: Colors.teal)),
        ],
      );
    }

    final dynamicSts = env.safeToSpend(allTxs);
    String text = formatter.format(dynamicSts);
    String subtitle = '';

    if (env.id == 'keinginan' || env.stsMode == StsMode.lumpSum) {
      subtitle = ' bebas untuk hari ini';
    } else if (env.stsMode == StsMode.frequency) {
      final freq = env.stsFrequencyTarget ?? 1;
      final perTx = dynamicSts / freq;
      text = formatter.format(perTx);
      subtitle = ' / tx ($freq x)';
    } else {
      subtitle = ' untuk hari ini';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            fontSize: 15,
            color: env.color,
          ),
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: env.color.withValues(alpha: 0.7),
            ),
          ),
      ],
    );
  }
}
