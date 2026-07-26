import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../envelopes/widgets/create_envelope_sheet.dart'; // For ThousandsFormatter
import '../../envelopes/providers/envelope_provider.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../providers/transactions_provider.dart';

class AddExpenseSheet extends ConsumerStatefulWidget {
  const AddExpenseSheet({super.key});

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  String? _selectedPocketId;
  Account? _selectedAccount;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  void _submitExpense() async {
    final textAmount = _amountController.text.replaceAll('.', '');
    final amount = double.tryParse(textAmount) ?? 0.0;

    if (amount <= 0 || _merchantController.text.isEmpty || _selectedPocketId == null || _selectedAccount == null) return;
    
    setState(() => _isSubmitting = true);
    
    final success = await ref.read(transactionsProvider.notifier).addExpense(
      amount,
      _selectedAccount!.id,
      _selectedPocketId,
      _merchantController.text,
      'Pengeluaran Manual',
      null, // No OCR items
    );
    
    setState(() => _isSubmitting = false);
    
    if (!mounted) return;
    
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mencatat pengeluaran')),
      );
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pengeluaran "${_merchantController.text}" berhasil dicatat!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final envelopesAsync = ref.watch(envelopesProvider);
    final envelopes = envelopesAsync.value ?? [];
    
    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.value ?? [];

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
              Text('Catat Pengeluaran Manual', style: theme.textTheme.titleLarge),
              IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _merchantController,
            decoration: const InputDecoration(
              labelText: 'Nama Merchant / Catatan',
              border: OutlineInputBorder(),
              prefixIcon: Icon(LucideIcons.edit3),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsFormatter()],
            style: theme.textTheme.displayMedium?.copyWith(fontSize: 24, color: AppColors.error),
            decoration: const InputDecoration(
              labelText: 'Nominal (Rp)',
              border: OutlineInputBorder(),
              prefixText: 'Rp ',
            ),
          ),
          const SizedBox(height: 16),
          Text('Pilih Rekening Sumber', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Account>(
                isExpanded: true,
                hint: const Text('Pilih Rekening'),
                value: _selectedAccount,
                items: accounts.map((acc) {
                  return DropdownMenuItem<Account>(
                    value: acc,
                    child: Text(acc.name),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedAccount = val;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Pilih Saku (Pocket)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Pilih Saku Tujuan'),
                value: _selectedPocketId,
                items: envelopes.expand((env) {
                  return env.pockets.map((pocket) {
                    return DropdownMenuItem<String>(
                      value: pocket.id,
                      child: Text('${env.name} -> ${pocket.name}'),
                    );
                  });
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedPocketId = val;
                  });
                },
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitExpense,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Simpan Pengeluaran'),
            ),
          ),
        ],
      ),
    );
  }
}
