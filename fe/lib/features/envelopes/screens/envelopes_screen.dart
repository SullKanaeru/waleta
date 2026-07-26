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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        // Summary Card — clean minimal
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Saldo',
                    style: theme.textTheme.labelMedium,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Waleta',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                formatter.format(totalRealBalance),
                style: theme.textTheme.displayMedium,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.lightMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Safe-to-Spend',
                            style: theme.textTheme.labelSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatter.format(totalSts),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.income,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 28, width: 0.5, color: AppColors.lightBorder),
                    Expanded(
                      child: InkWell(
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
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Belum Dialokasikan',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    LucideIcons.arrowUpRight,
                                    size: 10,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatter.format(unallocatedDisplay),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: unallocatedDisplay < 0
                                      ? AppColors.error
                                      : AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text('Dompet Saya', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),

        ...envelopes.map(
          (env) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
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
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightBorder),
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
                    color: env.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(env.iconData, color: env.color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    env.name,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 0.5,
              color: AppColors.lightBorder,
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saldo', style: theme.textTheme.labelSmall),
                    const SizedBox(height: 3),
                    Text(
                      formatter.format(env.allocatedAmount),
                      style: theme.textTheme.titleSmall?.copyWith(
                        letterSpacing: -0.3,
                      ),
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
                          size: 10,
                          color: env.color,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Safe-to-Spend',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: env.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
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
