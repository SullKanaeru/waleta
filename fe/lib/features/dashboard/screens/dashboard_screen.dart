import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../activity/providers/transactions_provider.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../envelopes/providers/envelope_provider.dart';
import '../../activity/widgets/edit_transaction_sheet.dart';
import '../../../core/theme/app_colors.dart';

import '../providers/rollover_provider.dart';
import '../widgets/rollover_dialog.dart';

// Provider for Privacy Blur
class PrivacyBlurNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }
}

final privacyBlurProvider = NotifierProvider<PrivacyBlurNotifier, bool>(
  PrivacyBlurNotifier.new,
);

// Provider for selected month in dashboard
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void setDate(int year, int month) {
    state = DateTime(year, month);
  }
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);

class MultiSelectState {
  final bool isMultiSelect;
  final Set<String> selectedIds;

  MultiSelectState({this.isMultiSelect = false, this.selectedIds = const {}});

  MultiSelectState copyWith({bool? isMultiSelect, Set<String>? selectedIds}) {
    return MultiSelectState(
      isMultiSelect: isMultiSelect ?? this.isMultiSelect,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

class MultiSelectNotifier extends Notifier<MultiSelectState> {
  @override
  MultiSelectState build() => MultiSelectState();

  void toggleMode(bool val) {
    state = state.copyWith(
      isMultiSelect: val,
      selectedIds: val ? state.selectedIds : {},
    );
  }

  void toggleSelection(String id) {
    final newSet = Set<String>.from(state.selectedIds);
    if (newSet.contains(id)) {
      newSet.remove(id);
      if (newSet.isEmpty) {
        state = state.copyWith(isMultiSelect: false, selectedIds: newSet);
        return;
      }
    } else {
      newSet.add(id);
    }
    state = state.copyWith(selectedIds: newSet, isMultiSelect: true);
  }

  void clear() {
    state = MultiSelectState();
  }
}

final multiSelectProvider =
    NotifierProvider<MultiSelectNotifier, MultiSelectState>(
      MultiSelectNotifier.new,
    );

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<RolloverState>(rolloverProvider, (previous, next) {
      if (next.isNewMonth && !next.hasShownDialog) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showRolloverDialog(context, next.savedAmount, () {
            // For now we just show a success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sisa saldo berhasil dipindahkan ke Tabungan!'),
              ),
            );
          });
          ref.read(rolloverProvider.notifier).markAsShown();
        });
      }
    });

    final isBlurred = ref.watch(privacyBlurProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final txsAsync = ref.watch(transactionsProvider);
    final accountsAsync = ref.watch(accountsProvider);

    final allTxs = txsAsync.value ?? [];
    final accounts = accountsAsync.value ?? [];

    final totalRealBalance = accounts.fold(
      0.0,
      (sum, acc) => sum + acc.balance,
    );

    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Filter transactions for Selected Month & Year
    final monthTxs =
        allTxs
            .where(
              (t) =>
                  t.date.year == selectedDate.year &&
                  t.date.month == selectedDate.month,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final totalExpense = monthTxs
        .where((t) => t.type == 'EXPENSE')
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = monthTxs
        .where((t) => t.type == 'INCOME')
        .fold(0.0, (sum, t) => sum + t.amount);

    final multiSelect = ref.watch(multiSelectProvider);

    return Scaffold(
      floatingActionButton:
          multiSelect.isMultiSelect && multiSelect.selectedIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hapus Transaksi?'),
                    content: Text(
                      'Anda yakin ingin menghapus ${multiSelect.selectedIds.length} transaksi terpilih?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref
                      .read(transactionsProvider.notifier)
                      .deleteTransactions(multiSelect.selectedIds.toList());
                  ref.read(multiSelectProvider.notifier).clear();
                }
              },
              backgroundColor: AppColors.error,
              icon: const Icon(LucideIcons.trash2, color: Colors.white),
              label: Text(
                'Hapus (${multiSelect.selectedIds.length})',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(transactionsProvider.notifier).refresh();
          ref.read(accountsProvider.notifier).refresh();
          ref.read(dashboardProvider.notifier).refresh();
          ref.read(envelopesProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 20,
                    right: 20,
                    bottom: 24,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderTop(context, ref, selectedDate),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryColumn(
                              'Pengeluaran',
                              formatter.format(totalExpense.abs()),
                              isBlurred,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryColumn(
                              'Pemasukan',
                              formatter.format(totalIncome),
                              isBlurred,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryColumn(
                              'Total Saldo',
                              formatter.format(totalRealBalance),
                              isBlurred,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Transaction History
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _showMonthYearPicker(
                              context,
                              ref,
                              selectedDate,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  DateFormat('MMMM yyyy').format(selectedDate),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  LucideIcons.chevronDown,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTransactionHistory(
                        context,
                        ref,
                        theme,
                        formatter,
                        monthTxs,
                        txsAsync.isLoading,
                        isBlurred,
                        selectedDate,
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildHeaderTop(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => GoRouter.of(context).push('/settings'),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.user,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Waleta',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => _showMonthYearPicker(context, ref, selectedDate),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.calendar,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryColumn(String label, String value, bool isBlurred) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: _BlurrableText(
            text: value,
            isBlurred: isBlurred,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  void _showMonthYearPicker(
    BuildContext context,
    WidgetRef ref,
    DateTime currentSelected,
  ) {
    int tempYear = currentSelected.year;
    final years = [2024, 2025, 2026, 2027];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          return Container(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 32,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pilih Periode', style: theme.textTheme.titleMedium),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          LucideIcons.x,
                          size: 20,
                          color: theme.disabledColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Year selector
                  Text('Tahun', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: years.map((y) {
                      final isSel = y == tempYear;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => tempYear = y),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSel
                                    ? AppColors.primary
                                    : theme.dividerColor,
                              ),
                            ),
                            child: Text(
                              '$y',
                              style: TextStyle(
                                color: isSel
                                    ? Colors.white
                                    : theme.textTheme.bodyMedium?.color,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Month grid
                  Text('Bulan', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: 12,
                    itemBuilder: (context, idx) {
                      final isSel =
                          (idx + 1 == currentSelected.month) &&
                          (tempYear == currentSelected.year);
                      return GestureDetector(
                        onTap: () {
                          ref
                              .read(selectedDateProvider.notifier)
                              .setDate(tempYear, idx + 1);
                          Navigator.pop(context);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel
                                  ? AppColors.primary
                                  : theme.dividerColor,
                            ),
                          ),
                          child: Text(
                            months[idx],
                            style: TextStyle(
                              color: isSel
                                  ? Colors.white
                                  : theme.textTheme.bodyMedium?.color,
                              fontWeight: isSel
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionHistory(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    NumberFormat formatter,
    List<Transaction> txs,
    bool isLoading,
    bool isBlurred,
    DateTime selectedDate,
  ) {
    if (isLoading) {
      return Skeletonizer(
        enabled: true,
        child: Column(
          children: [
            _buildDayGroupDummy(
              theme,
              formatter,
              '9 Apr Kamis',
              'Pengeluaran: 48.000',
              [
                (
                  'minyak goreng gela...',
                  -6000.0,
                  LucideIcons.shoppingBag,
                  Colors.amber,
                ),
                ('merica', -2000.0, LucideIcons.shoppingBag, Colors.amber),
                ('makan', -10000.0, LucideIcons.utensils, Colors.teal),
              ],
            ),
          ],
        ),
      );
    }

    if (txs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Icon(LucideIcons.inbox, size: 40, color: theme.disabledColor),
              const SizedBox(height: 12),
              Text(
                'Belum ada transaksi di ${DateFormat('MMMM yyyy').format(selectedDate)}',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Group by Date string
    final groups = <String, List<Transaction>>{};
    for (final tx in txs) {
      final key = DateFormat('dd MMM yyyy').format(tx.date);
      groups.putIfAbsent(key, () => []).add(tx);
    }

    return Column(
      children: groups.entries.map((entry) {
        final dateStr = entry.key;
        final dayTxs = entry.value;
        final dayExpense = dayTxs
            .where((t) => t.type == 'EXPENSE')
            .fold(0.0, (sum, t) => sum + t.amount);
        final dayIncome = dayTxs
            .where((t) => t.type == 'INCOME')
            .fold(0.0, (sum, t) => sum + t.amount);

        String summaryText = '';
        if (dayExpense < 0 && dayIncome > 0) {
          summaryText =
              '+${formatter.format(dayIncome)} / -${formatter.format(dayExpense.abs())}';
        } else if (dayExpense < 0) {
          summaryText = '-${formatter.format(dayExpense.abs())}';
        } else if (dayIncome > 0) {
          summaryText = '+${formatter.format(dayIncome)}';
        } else {
          // Hanya ada ALLOCATION atau 0
          summaryText = '';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateStr,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(summaryText, style: theme.textTheme.labelSmall),
                ],
              ),
            ),
            ...dayTxs.map((tx) {
              final isIncome = tx.type == 'INCOME';
              final isExpense = tx.type == 'EXPENSE';
              final isAllocation = tx.type == 'ALLOCATION';
              
              final multiSelect = ref.watch(multiSelectProvider);
              final isSelected = multiSelect.selectedIds.contains(tx.id);

              return GestureDetector(
                onLongPress: () {
                  ref.read(multiSelectProvider.notifier).toggleSelection(tx.id);
                },
                onTap: () {
                  if (multiSelect.isMultiSelect) {
                    ref
                        .read(multiSelectProvider.notifier)
                        .toggleSelection(tx.id);
                  } else {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) =>
                          EditTransactionSheet(transaction: tx),
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : Border.all(color: Colors.transparent, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: (isAllocation 
                                  ? Colors.orange 
                                  : (isIncome ? AppColors.primary : AppColors.error))
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isAllocation
                              ? LucideIcons.arrowRightLeft
                              : (isIncome ? LucideIcons.arrowDownLeft : LucideIcons.shoppingBag),
                          color: isAllocation 
                                  ? Colors.orange 
                                  : (isIncome ? AppColors.primary : AppColors.error),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.merchantName,
                              style: theme.textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(isAllocation ? 'Alokasi ke Amplop' : 'Rekening', style: theme.textTheme.labelSmall),
                          ],
                        ),
                      ),
                      _BlurrableText(
                        text: isAllocation
                            ? formatter.format(tx.amount)
                            : (isIncome
                                ? '+${formatter.format(tx.amount)}'
                                : '-${formatter.format(tx.amount.abs())}'),
                        isBlurred: isBlurred,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isAllocation
                              ? Colors.orange
                              : (isIncome
                                  ? AppColors.primary
                                  : theme.colorScheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDayGroupDummy(
    ThemeData theme,
    NumberFormat formatter,
    String dateStr,
    String summaryStr,
    List<(String, double, IconData, Color)> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(summaryStr, style: theme.textTheme.labelSmall),
            ],
          ),
        ),
        ...items.map((item) {
          final (title, amount, icon, color) = item;
          final isIncome = amount >= 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
                Text(
                  isIncome
                      ? '+${formatter.format(amount)}'
                      : '-${formatter.format(amount.abs())}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isIncome
                        ? AppColors.primary
                        : theme.colorScheme.onSurface,
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

class _BlurrableText extends StatelessWidget {
  final String text;
  final bool isBlurred;
  final TextStyle? style;

  const _BlurrableText({
    required this.text,
    required this.isBlurred,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (isBlurred) {
      return ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Text(text.replaceAll(RegExp(r'[0-9]'), '*'), style: style),
      );
    }
    return Text(text, style: style);
  }
}
