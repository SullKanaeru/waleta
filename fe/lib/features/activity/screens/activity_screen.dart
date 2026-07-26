import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/ocr_result.dart';
import '../widgets/assign_pocket_sheet.dart';
import '../widgets/add_expense_sheet.dart';
import 'camera_scanner_screen.dart';
import '../providers/transactions_provider.dart';

class ActivityScreen extends ConsumerWidget {
  final bool showAppBar;
  const ActivityScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: showAppBar ? AppBar(
        title: const Text('Pengeluaran'),
        centerTitle: false,
      ) : null,
      body: _buildExpenseContent(context, ref, theme, formatter),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddExpenseOptions(context);
        },
        icon: const Icon(LucideIcons.plus),
        label: const Text('Catat Pengeluaran'),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddExpenseOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(LucideIcons.camera, color: AppColors.primary),
              ),
              title: const Text('Pindai Struk OCR (AI Scanner)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Otomatis pecah item & alokasi amplop'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push<OCRResult>(
                  context,
                  MaterialPageRoute(builder: (context) => const CameraScannerScreen()),
                );
                if (result != null && context.mounted) {
                  _showAssignPocketSheet(context, result);
                }
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(LucideIcons.edit3, color: AppColors.error),
              ),
              title: const Text('Catat Manual', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Input nominal secara manual'),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const AddExpenseSheet(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

Widget _buildExpenseContent(BuildContext context, WidgetRef ref, ThemeData theme, NumberFormat formatter) {
    final inboxAsync = ref.watch(inboxProvider);
    final inbox = inboxAsync.value ?? [];
    
    final txsAsync = ref.watch(transactionsProvider);
    final txs = txsAsync.value ?? [];
    final expenseTxs = txs.where((tx) => tx.amount < 0).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Pending Inbox Section (Triage)
        if (inboxAsync.isLoading)
          Skeletonizer(
            enabled: true,
            child: _buildPendingDummy(theme, formatter),
          )
        else if (inbox.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.inbox, color: AppColors.warning),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '${inbox.length} transaksi menunggak untuk dialokasikan (Triage)',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.warning, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...inbox.map((tx) => _buildPendingTransactionItem(
            context: context,
            transactionId: tx.id,
            merchantName: tx.merchantName,
            amount: tx.amount.abs(),
            source: 'Rekening',
            formatter: formatter,
          )),
          const SizedBox(height: 32),
        ],

        Text('Riwayat Pengeluaran', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        txsAsync.when(
          loading: () => Skeletonizer(
            enabled: true,
            child: Column(
              children: [
                _buildDummyExpense(theme, formatter, 'Belanja Mingguan', -350000),
                _buildDummyExpense(theme, formatter, 'Kopi Pagi', -25000),
              ],
            ),
          ),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (_) {
            if (expenseTxs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(LucideIcons.shoppingBag, size: 48, color: theme.disabledColor),
                      const SizedBox(height: 16),
                      Text('Belum ada catatan pengeluaran.', style: TextStyle(color: theme.disabledColor)),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: expenseTxs.map((tx) {
                return _buildTransactionItem(
                  context: context,
                  title: tx.merchantName,
                  amount: tx.amount,
                  source: 'Rekening',
                  icon: LucideIcons.shoppingBag,
                  color: AppColors.error,
                  formatter: formatter,
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildPendingDummy(ThemeData theme, NumberFormat formatter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.helpCircle, color: AppColors.warning),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Supermarket Dummy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Dari: Rekening', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text(formatter.format(150000), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildDummyExpense(ThemeData theme, NumberFormat formatter, String title, double amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          child: const Icon(LucideIcons.shoppingBag, color: AppColors.error, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Rekening'),
        trailing: Text(
          formatter.format(amount),
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }

  Widget _buildPendingTransactionItem({
    required BuildContext context,
    required String transactionId,
    required String merchantName,
    required double amount,
    required String source,
    required NumberFormat formatter,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AssignPocketSheet(
            transactionId: transactionId,
            merchantName: merchantName,
            amount: amount,
            source: source,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.warning.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.helpCircle, color: AppColors.warning),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(merchantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Dari: $source', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatter.format(amount),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Triage', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem({
    required BuildContext context,
    required String title,
    required double amount,
    required String source,
    required IconData icon,
    required Color color,
    required NumberFormat formatter,
    List<Map<String, dynamic>>? items,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(LucideIcons.link, size: 12, color: theme.textTheme.bodyMedium?.color),
              const SizedBox(width: 4),
              Text(source, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
            ],
          ),
        ),
        trailing: Text(
          formatter.format(amount),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: theme.colorScheme.onSurface,
          ),
        ),
        children: items != null
            ? [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.03),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.scanLine, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('Ekstraksi Struk OCR (JSONB)', style: theme.textTheme.labelLarge?.copyWith(color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['name'], style: theme.textTheme.bodyMedium),
                            Text(formatter.format(item['price']), style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ]
            : [],
      ),
    );
  }

  void _showAssignPocketSheet(BuildContext context, OCRResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssignPocketSheet(
        merchantName: result.merchantName.isNotEmpty ? result.merchantName : result.date,
        amount: result.totalAmount,
        source: 'OCR Scanner',
      ),
    );
  }
}
