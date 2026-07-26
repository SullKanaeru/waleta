import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../providers/envelope_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import 'create_envelope_sheet.dart'; // for ThousandsFormatter
import 'package:flutter_animate/flutter_animate.dart';

class AllocateFundsSheet extends ConsumerStatefulWidget {
  final String? initialMasterId;
  final String? initialPocketId;

  const AllocateFundsSheet({
    super.key,
    this.initialMasterId,
    this.initialPocketId,
  });

  @override
  ConsumerState<AllocateFundsSheet> createState() => _AllocateFundsSheetState();
}

class _AllocateFundsSheetState extends ConsumerState<AllocateFundsSheet> {
  Account? _selectedAccount;
  bool _usePercentage = false;

  final _kebController = TextEditingController();
  final _keiController = TextEditingController();
  final _tabController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _kebController.dispose();
    _keiController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  double _getCalculatedAmountFor(TextEditingController controller) {
    if (_selectedAccount == null) return 0.0;
    final text = controller.text.trim();
    if (text.isEmpty) return 0.0;

    if (_usePercentage) {
      final pct = double.tryParse(text) ?? 0.0;
      return (_selectedAccount!.balance * (pct / 100.0)).clamp(
        0,
        _selectedAccount!.balance,
      );
    } else {
      final textAmount = text.replaceAll('.', '');
      return double.tryParse(textAmount) ?? 0.0;
    }
  }

  double get _amountKeb => _getCalculatedAmountFor(_kebController);
  double get _amountKei => _getCalculatedAmountFor(_keiController);
  double get _amountTab => _getCalculatedAmountFor(_tabController);

  double get _totalInputAmount => _amountKeb + _amountKei + _amountTab;

  double _getEffectiveLimit() {
    final accountBalance = _selectedAccount?.balance ?? 0.0;
    final safeToSpend = ref.read(safeToSpendProvider);
    return safeToSpend < accountBalance ? safeToSpend : accountBalance;
  }

  Future<void> _submitAllocation() async {
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih rekening asal terlebih dahulu'),
        ),
      );
      return;
    }

    final amtKeb = _amountKeb;
    final amtKei = _amountKei;
    final amtTab = _amountTab;
    final totalAmt = amtKeb + amtKei + amtTab;

    if (totalAmt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal alokasi harus lebih dari 0')),
      );
      return;
    }

    final effectiveLimit = _getEffectiveLimit();
    if (totalAmt > effectiveLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nominal alokasi melebihi aset yang belum dialokasikan',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    bool allSuccess = true;
    final notifier = ref.read(envelopesProvider.notifier);

    // Allocate Kebutuhan
    if (amtKeb > 0) {
      final success = await notifier.allocateFunds(
        _selectedAccount!.id,
        'kebutuhan',
        null,
        amtKeb,
      );
      if (!success) allSuccess = false;
    }

    // Allocate Keinginan
    if (amtKei > 0) {
      final success = await notifier.allocateFunds(
        _selectedAccount!.id,
        'keinginan',
        null,
        amtKei,
      );
      if (!success) allSuccess = false;
    }

    // Allocate Tabungan
    if (amtTab > 0) {
      final success = await notifier.allocateFunds(
        _selectedAccount!.id,
        'tabungan',
        null,
        amtTab,
      );
      if (!success) allSuccess = false;
    }

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (allSuccess) {
      ref.read(accountsProvider.notifier).refresh();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alokasi dana serentak berhasil disimpan!'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beberapa alokasi dana gagal diproses')),
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

    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.value ?? [];

    if (_selectedAccount == null && accounts.isNotEmpty) {
      _selectedAccount = accounts.first;
    }

    final accountBalance = _selectedAccount?.balance ?? 0.0;
    final safeToSpend = ref.watch(safeToSpendProvider);
    final balance = safeToSpend < accountBalance ? safeToSpend : accountBalance;

    // Remaining calculation for Gunakan Sisa under each controller
    final sisaKeb = (balance - _amountKei - _amountTab).clamp(0.0, balance);
    final sisaKei = (balance - _amountKeb - _amountTab).clamp(0.0, balance);
    final sisaTab = (balance - _amountKeb - _amountKei).clamp(0.0, balance);

    final double progress = balance > 0 ? (_totalInputAmount / balance) : 0.0;
    final bool isExceeded = _totalInputAmount > balance;
    final bool isComplete = (_totalInputAmount - balance).abs() < 1.0;

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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Alokasi Dana Serentak',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Rekening Asal (Source Account)
            Text('Asal Asset', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                accountsAsync.whenData((accountList) {
                  if (accountList.isNotEmpty) {
                    final unallocated = ref.read(safeToSpendProvider);
                    _showAccountPicker(
                      context,
                      accountList,
                      formatter,
                      unallocated,
                    );
                  }
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _selectedAccount != null
                        ? AppColors.primary
                        : theme.dividerColor.withValues(alpha: 0.15),
                    width: _selectedAccount != null ? 1.8 : 1.5,
                  ),
                  boxShadow: _selectedAccount != null
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.landmark,
                      color: _selectedAccount != null
                          ? AppColors.primary
                          : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedAccount != null
                            ? '${_selectedAccount!.name} (${formatter.format(_selectedAccount!.balance)})'
                            : 'Select an option',
                        style: TextStyle(
                          fontWeight: _selectedAccount != null
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 14.5,
                          color: _selectedAccount != null
                              ? theme.textTheme.bodyLarge?.color
                              : Colors.grey.shade500,
                        ),
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronDown,
                      color: _selectedAccount != null
                          ? AppColors.primary
                          : Colors.grey.shade400,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedAccount != null) ...[
              const SizedBox(height: 4),
              Text(
                'Belum Dialokasikan: ${formatter.format(balance)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.accentAmber,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 2. Metode Alokasi (Global Mode Toggle)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Metode Alokasi', style: theme.textTheme.titleMedium),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<bool>(
                      value: false,
                      label: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          'Rp',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          '%',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                  selected: {_usePercentage},
                  onSelectionChanged: (Set<bool> selection) {
                    setState(() {
                      _usePercentage = selection.first;
                      // Clear values when toggling to avoid mismatched calculations
                      _kebController.clear();
                      _keiController.clear();
                      _tabController.clear();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Daftar Amplop (Kebutuhan, Keinginan, Tabungan)

            // --- KEBUTUHAN CARD ---
            _buildEnvelopeInputCard(
              theme: theme,
              formatter: formatter,
              label: 'Kebutuhan',
              icon: LucideIcons.shoppingBag,
              color: AppColors.primary,
              controller: _kebController,
              calculatedValue: _amountKeb,
              sisaAmount: sisaKeb,
            ),
            const SizedBox(height: 16),

            // --- KEINGINAN CARD ---
            () {
              String? nudge;
              if (balance > 0 && _totalInputAmount > 0) {
                final ratio =
                    _amountKei /
                    balance; // Or against total input? "rasio maksimal 30% untuk Keinginan"
                if (ratio > 0.3) {
                  nudge =
                      'Tips: Perencana keuangan biasanya menyarankan rasio maksimal 30% untuk Keinginan agar masa depanmu tetap aman.';
                }
              }
              return _buildEnvelopeInputCard(
                theme: theme,
                formatter: formatter,
                label: 'Keinginan',
                icon: LucideIcons.coffee,
                color: AppColors.accentAmber,
                controller: _keiController,
                calculatedValue: _amountKei,
                sisaAmount: sisaKei,
                nudgeText: nudge,
                nudgeColor: AppColors.warning,
              );
            }(),
            const SizedBox(height: 16),

            // --- TABUNGAN CARD ---
            () {
              String? nudge;
              if (balance > 0 && _totalInputAmount > 0) {
                final ratio = _amountTab / balance;
                if (ratio > 0 && ratio < 0.2) {
                  nudge =
                      'Tips: Disarankan mengalokasikan minimal 20% untuk Tabungan sebagai dana darurat atau investasi.';
                }
              }
              return _buildEnvelopeInputCard(
                theme: theme,
                formatter: formatter,
                label: 'Tabungan',
                icon: LucideIcons.wallet,
                color: Colors.teal,
                controller: _tabController,
                calculatedValue: _amountTab,
                sisaAmount: sisaTab,
                nudgeText: nudge,
                nudgeColor: Colors.teal,
              );
            }(),

            const SizedBox(height: 24),

            // 4. Progress Alokasi Status Bar
            () {
              Color barColor;
              Widget statusWidget;

              if (isExceeded) {
                barColor = AppColors.error;
                statusWidget =
                    Text(
                          '⚠️ Melebihi Saldo Pada Dompet',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .shake(
                          duration: 300.ms,
                          hz: 6,
                          curve: Curves.easeInOut,
                        );
              } else if (isComplete) {
                barColor = Colors.green;
                statusWidget = const Text(
                  'Semua saldo dialokasikan!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                );
              } else {
                barColor = Colors.orange;
                final remaining = balance - _totalInputAmount;
                statusWidget = Text(
                  'Sisa Rp ${formatter.format(remaining).replaceAll('Rp ', '')}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress Alokasi',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      statusWidget,
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: theme.dividerColor.withValues(
                        alpha: 0.1,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      minHeight: 10,
                    ),
                  ),
                ],
              );
            }(),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isSubmitting || !isComplete)
                    ? null
                    : _submitAllocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isComplete
                      ? Colors.green
                      : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                    : Text(
                        isComplete
                            ? 'Alokasikan Sekarang'
                            : 'Alokasi Belum 100%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvelopeInputCard({
    required ThemeData theme,
    required NumberFormat formatter,
    required String label,
    required IconData icon,
    required Color color,
    required TextEditingController controller,
    required double calculatedValue,
    required double sisaAmount,
    String? nudgeText,
    Color? nudgeColor,
  }) {
    final balance = _selectedAccount?.balance ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: _usePercentage
                ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                : [ThousandsFormatter()],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '0',
              prefixText: _usePercentage ? null : 'Rp ',
              suffixText: _usePercentage ? '%' : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          if (_usePercentage && balance > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Setara dengan:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  formatter.format(calculatedValue),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
          if (sisaAmount > 0) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                if (_usePercentage) {
                  final pct = (sisaAmount / balance) * 100;
                  controller.text = pct.toStringAsFixed(1);
                } else {
                  controller.text = formatter
                      .format(sisaAmount)
                      .replaceAll('Rp ', '');
                }
                setState(() {});
              },
              child: Text(
                _usePercentage
                    ? 'Gunakan sisa ${((sisaAmount / balance) * 100).toStringAsFixed(1)}%'
                    : 'Gunakan sisa Rp ${formatter.format(sisaAmount).replaceAll('Rp ', '')}',
                style: TextStyle(
                  color: color,
                  decoration: TextDecoration.underline,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          if (nudgeText != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (nudgeColor ?? color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (nudgeColor ?? color).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.lightbulb,
                    size: 16,
                    color: nudgeColor ?? color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nudgeText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: nudgeColor ?? color,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAccountPicker(
    BuildContext context,
    List<Account> accountList,
    NumberFormat formatter,
    double unallocatedBalance,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        String searchQuery = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = accountList
                .where(
                  (a) =>
                      a.name.toLowerCase().contains(searchQuery.toLowerCase()),
                )
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Pilih Asal Asset',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      onChanged: (val) =>
                          setModalState(() => searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          LucideIcons.search,
                          size: 18,
                          color: Colors.grey,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: theme.dividerColor.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.dividerColor.withValues(alpha: 0.1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.dividerColor.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final acc = filtered[i];
                        final isSel = _selectedAccount?.id == acc.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: Icon(
                              LucideIcons.landmark,
                              color: isSel
                                  ? AppColors.primary
                                  : Colors.grey.shade700,
                              size: 20,
                            ),
                            title: Text(
                              acc.name,
                              style: TextStyle(
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSel
                                    ? AppColors.primary
                                    : theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            subtitle: Text(
                              formatter.format(acc.balance),
                              style: TextStyle(
                                fontSize: 12,
                                color: isSel
                                    ? AppColors.primary.withValues(alpha: 0.8)
                                    : Colors.grey,
                              ),
                            ),
                            trailing: isSel
                                ? const Icon(
                                    LucideIcons.check,
                                    color: AppColors.primary,
                                    size: 20,
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedAccount = acc;
                              });
                              Navigator.pop(ctx);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
