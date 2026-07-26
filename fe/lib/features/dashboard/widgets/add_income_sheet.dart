import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../envelopes/widgets/create_envelope_sheet.dart'; // For ThousandsFormatter
import '../../accounts/providers/accounts_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../activity/providers/transactions_provider.dart';

class AddIncomeSheet extends ConsumerStatefulWidget {
  const AddIncomeSheet({super.key});

  @override
  ConsumerState<AddIncomeSheet> createState() => _AddIncomeSheetState();
}

class _AddIncomeSheetState extends ConsumerState<AddIncomeSheet> {
  final _amountController = TextEditingController();
  Account? _selectedAccount;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submitIncome() async {
    final textAmount = _amountController.text.replaceAll('.', '');
    final amount = double.tryParse(textAmount) ?? 0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih besar dari 0')),
      );
      return;
    }
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih rekening tujuan terlebih dahulu'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await ref
        .read(transactionsProvider.notifier)
        .addIncome(
          amount,
          _selectedAccount!.id,
          'Pemasukan Manual',
          'Pemasukan',
        );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mencatat uang masuk')),
      );
      return;
    }

    // Refresh dashboard to get updated total/safe-to-spend
    ref.read(dashboardProvider.notifier).refresh();

    Navigator.pop(context);

    // Simulate auto-sweeping dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(LucideIcons.sparkles, color: AppColors.accentAmber),
            const SizedBox(width: 8),
            const Text('Auto-Sweeping Aktif!'),
          ],
        ),
        content: Text(
          'Uang masuk sebesar ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount)} dideteksi dari ${_selectedAccount!.name}.\n\nSistem telah membaginya ke Master Kebutuhan, Keinginan, dan Tabungan sesuai aturan Anda (50/30/20).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Luar Biasa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.value ?? [];
    if (_selectedAccount == null && accounts.isNotEmpty) {
      _selectedAccount = accounts.first;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Catat Uang Masuk', style: theme.textTheme.titleLarge),
              IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsFormatter()],
            style: theme.textTheme.displayMedium?.copyWith(fontSize: 32),
            decoration: const InputDecoration(
              labelText: 'Nominal (Rp)',
              border: OutlineInputBorder(),
              prefixText: 'Rp ',
            ),
          ),
          const SizedBox(height: 24),
          Text('Pilih Rekening Tujuan:', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),

          DropdownButtonFormField<Account>(
            decoration: const InputDecoration(border: OutlineInputBorder()),
            hint: const Text('Pilih Rekening'),
            initialValue: _selectedAccount,
            items: accounts.map((acc) {
              return DropdownMenuItem(value: acc, child: Text(acc.name));
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedAccount = val;
              });
            },
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitIncome,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Simpan & Otomatisasikan'),
            ),
          ),
        ],
      ),
    );
  }
}
