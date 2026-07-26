import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../core/theme/app_colors.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../accounts/screens/reconcile_balance_sheet.dart';
import '../../accounts/widgets/add_account_sheet.dart';
import '../providers/transactions_provider.dart';

class IncomeScreen extends ConsumerWidget {
  final bool showAppBar;
  const IncomeScreen({super.key, this.showAppBar = true});

  bool _isCashAccount(Account acc) {
    final n = acc.name.toLowerCase();
    return n.contains('tunai') ||
        n.contains('cash') ||
        n.contains('dompet') ||
        n.contains('saku') ||
        n.contains('gopay') ||
        n.contains('ovo') ||
        n.contains('dana') ||
        n.contains('shopee') ||
        n.contains('linkaja') ||
        n.contains('flazz') ||
        n.contains('emoney') ||
        n.contains('e-money');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final accountsAsync = ref.watch(accountsProvider);
    final txsAsync = ref.watch(transactionsProvider);

    final accounts = accountsAsync.value ?? [];
    final allTxs = txsAsync.value ?? [];

    final totalBalance = accounts.fold(0.0, (sum, acc) => sum + acc.balance);

    return Scaffold(
      appBar: showAppBar
          ? AppBar(title: const Text('Aset & Rekening'), centerTitle: false)
          : null,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Total Balance Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.landmark, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Total Saldo Kamu',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  formatter.format(totalBalance),
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Header Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Rekening & Tunai',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AddAccountSheet(),
                  );
                },
                icon: const Icon(LucideIcons.plus, size: 16),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          accountsAsync.when(
            loading: () => Skeletonizer(
              enabled: true,
              child: Column(
                children:
                    [
                      Account(
                        id: 'skel1',
                        name: 'Bank BCA Utama',
                        balance: 15000000,
                      ),
                      Account(
                        id: 'skel2',
                        name: 'Dompet Digital Gopay',
                        balance: 500000,
                      ),
                    ].map((acc) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.05),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.accentAmber.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.creditCard,
                              color: AppColors.accentAmber,
                            ),
                          ),
                          title: Text(
                            acc.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Saldo: ${formatter.format(acc.balance)}',
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (accountsList) {
              if (accountsList.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.wallet,
                          size: 48,
                          color: theme.disabledColor,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum ada rekening atau dompet tunai.',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Silakan tambahkan rekening untuk melacak arus kas Anda.',
                          style: TextStyle(
                            color: theme.disabledColor,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const AddAccountSheet(),
                            );
                          },
                          icon: const Icon(LucideIcons.plus, size: 18),
                          label: const Text('Tambah Rekening Sekarang'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final bankAccounts = accountsList
                  .where((a) => !_isCashAccount(a))
                  .toList();
              final cashAccounts = accountsList
                  .where((a) => _isCashAccount(a))
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. REKENING BANK
                  if (bankAccounts.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 4,
                        bottom: 10,
                        top: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.landmark,
                            size: 16,
                            color: theme.disabledColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Rekening Bank',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: theme.disabledColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...bankAccounts.map(
                      (acc) => _buildAccountTile(
                        context,
                        ref,
                        theme,
                        formatter,
                        acc,
                        allTxs,
                        isBank: true,
                      ),
                    ),
                  ],

                  // 2. DOMPET & TUNAI
                  if (cashAccounts.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.only(
                        left: 4,
                        bottom: 10,
                        top: bankAccounts.isNotEmpty ? 20 : 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.wallet,
                            size: 16,
                            color: theme.disabledColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Dompet & Tunai',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: theme.disabledColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...cashAccounts.map(
                      (acc) => _buildAccountTile(
                        context,
                        ref,
                        theme,
                        formatter,
                        acc,
                        allTxs,
                        isBank: false,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildAccountTile(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    NumberFormat formatter,
    Account acc,
    List allTxs, {
    required bool isBank,
  }) {
    final displayBalance = acc.balance;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (isBank ? AppColors.primary : AppColors.accentAmber)
                .withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isBank ? LucideIcons.creditCard : LucideIcons.wallet,
            color: isBank ? AppColors.primary : AppColors.accentAmber,
            size: 22,
          ),
        ),
        title: Text(
          acc.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Saldo: ${formatter.format(displayBalance)}',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: IconButton(
          onPressed: () => _showReconcileSheet(context, ref, acc),
          icon: const Icon(LucideIcons.refreshCw, size: 14),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  void _showReconcileSheet(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReconcileBalanceSheet(account: account),
    );
  }
}
