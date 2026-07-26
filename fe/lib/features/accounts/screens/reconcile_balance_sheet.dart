import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/accounts_provider.dart';
import '../../envelopes/providers/envelope_provider.dart';
import '../../envelopes/widgets/create_envelope_sheet.dart'; // For ThousandsFormatter

class ReconcileBalanceSheet extends ConsumerStatefulWidget {
  final Account account;

  const ReconcileBalanceSheet({super.key, required this.account});

  @override
  ConsumerState<ReconcileBalanceSheet> createState() =>
      _ReconcileBalanceSheetState();
}

class _ReconcileBalanceSheetState extends ConsumerState<ReconcileBalanceSheet> {
  final _amountController = TextEditingController();
  double _difference = 0.0;
  String? _selectedPocketId;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_calculateDifference);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _calculateDifference() {
    final textAmount = _amountController.text.replaceAll('.', '');
    final inputAmount = double.tryParse(textAmount) ?? 0.0;

    setState(() {
      _difference = inputAmount - widget.account.balance;
    });
  }

  void _submitReconciliation() async {
    final textAmount = _amountController.text.replaceAll('.', '');
    final inputAmount = double.tryParse(textAmount) ?? 0.0;

    if (inputAmount <= 0) return;

    final success = await ref
        .read(accountsProvider.notifier)
        .reconcileBalance(
          widget.account.id,
          inputAmount,
          _difference,
          _selectedPocketId,
        );

    if (!mounted) return;
    Navigator.pop(context);

    if (success) {
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Koreksi saldo berhasil disimpan! Selisih: ${formatter.format(_difference)}',
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui saldo rekening.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final envelopesAsync = ref.watch(envelopesProvider);
    final envelopes = envelopesAsync.value ?? [];

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
              Text(
                'Koreksi Saldo: ${widget.account.name}',
                style: theme.textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Saldo Tercatat: ${formatter.format(widget.account.balance)}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsFormatter()],
            decoration: const InputDecoration(
              labelText: 'Saldo Asli (di M-Banking)',
              border: OutlineInputBorder(),
              prefixText: 'Rp ',
            ),
          ),
          const SizedBox(height: 24),

          if (_amountController.text.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _difference == 0
                    ? Colors.grey.withValues(alpha: 0.1)
                    : _difference > 0
                    ? AppColors.accentAmber.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _difference == 0
                        ? LucideIcons.checkCircle
                        : LucideIcons.alertTriangle,
                    color: _difference == 0
                        ? Colors.grey
                        : _difference > 0
                        ? AppColors.accentAmber
                        : AppColors.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _difference == 0
                          ? 'Saldo sudah sesuai.'
                          : 'Terdapat selisih ${formatter.format(_difference)}.\nTransaksi "Koreksi Saldo Sistem" akan dibuat untuk menyamakan saldo.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (envelopes.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: _selectedPocketId,
                hint: const Text('Pilih Kategori / Saku (Wajib)'),
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: [
                  for (var env in envelopes) ...[
                    DropdownMenuItem(
                      value: env.id,
                      child: Text(
                        env.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    for (var pocket in env.pockets)
                      DropdownMenuItem(
                        value: pocket.id,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Text('- ${pocket.name}'),
                        ),
                      ),
                  ],
                ],
                onChanged: (val) => setState(() => _selectedPocketId = val),
              ),
            const SizedBox(height: 24),
          ],

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _amountController.text.isNotEmpty &&
                      _difference != 0 &&
                      _selectedPocketId != null
                  ? _submitReconciliation
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Simpan Koreksi'),
            ),
          ),
        ],
      ),
    );
  }
}
