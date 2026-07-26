import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../envelopes/models/envelope.dart';
import '../../envelopes/providers/envelope_provider.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../providers/transactions_provider.dart';

class AssignPocketSheet extends ConsumerStatefulWidget {
  final String? transactionId;
  final String merchantName;
  final double amount;
  final String source;

  const AssignPocketSheet({
    super.key,
    this.transactionId,
    required this.merchantName,
    required this.amount,
    required this.source,
  });

  @override
  ConsumerState<AssignPocketSheet> createState() => _AssignPocketSheetState();
}

class _AssignPocketSheetState extends ConsumerState<AssignPocketSheet> {
  String? _selectedPocketId;
  String? _selectedAccountId;
  bool _autoCategorize = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accounts = ref.read(accountsProvider).value ?? [];
      if (accounts.isNotEmpty) {
        setState(() {
          _selectedAccountId = accounts.first.id;
        });
      }
    });
  }

  int _getRemainingDays() {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final remaining = lastDay - now.day + 1;
    return remaining > 0 ? remaining : 1;
  }

  void _submitAssignment() async {
    if (_selectedPocketId == null) return;

    final envelopes = ref.read(envelopesProvider).value ?? [];
    final allTxs = ref.read(transactionsProvider).value ?? [];

    // Find envelope and pocket
    Envelope? selectedEnv;
    Pocket? selectedPocket;
    for (var env in envelopes) {
      for (var pocket in env.pockets) {
        if (pocket.id == _selectedPocketId) {
          selectedEnv = env;
          selectedPocket = pocket;
          break;
        }
      }
    }

    if (selectedEnv != null && selectedPocket != null) {
      final pocketSts = selectedPocket.calculateSts(
        selectedEnv.id,
        _getRemainingDays(),
        allTxs,
      );
      final envSts = selectedEnv.safeToSpend(allTxs);
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );

      String? warningMessage;
      if (widget.amount > pocketSts &&
          selectedPocket.stsMode != StsMode.locked &&
          selectedEnv.id != 'tabungan') {
        warningMessage =
            'Nominal transaksi (${formatter.format(widget.amount)}) melebihi Safe-to-Spend dari Saku ${selectedPocket.name} (${formatter.format(pocketSts)}).';
      } else if (widget.amount > envSts && selectedEnv.id != 'tabungan') {
        warningMessage =
            'Nominal transaksi (${formatter.format(widget.amount)}) melebihi Safe-to-Spend dari Amplop ${selectedEnv.name} (${formatter.format(envSts)}).';
      }

      if (warningMessage != null) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('⚠️ Melebihi Safe-to-Spend'),
            content: Text(
              '$warningMessage\n\nApakah Anda tetap ingin melanjutkan alokasi?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Lanjutkan'),
              ),
            ],
          ),
        );
        if (confirm != true) return;
      }
    }

    setState(() => _isSaving = true);
    bool success = false;

    if (widget.transactionId != null) {
      success = await ref.read(inboxProvider.notifier).assignInbox(
        widget.transactionId!,
        _selectedPocketId!,
        _autoCategorize,
      );
    } else {
      final accounts = ref.read(accountsProvider).value ?? [];
      final accountId = _selectedAccountId ?? (accounts.isNotEmpty ? accounts.first.id : 'a_default_cash');
      success = await ref.read(transactionsProvider.notifier).addExpense(
        widget.amount,
        accountId,
        _selectedPocketId!,
        widget.merchantName,
        'Transaksi dari ${widget.source}',
        null,
      );
    }

    setState(() => _isSaving = false);

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Transaksi ${widget.merchantName} berhasil dicatat! ${_autoCategorize ? 'Kategori disimpan.' : ''}',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan alokasi transaksi.')),
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
    final envelopes = ref.watch(envelopesProvider);
    final accounts = ref.watch(accountsProvider);

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
              Text('Alokasi Pengeluaran', style: theme.textTheme.titleLarge),
              IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Transaction Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.landmark,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.merchantName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Metode: ${widget.source}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  formatter.format(widget.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 1. Choose Target Pocket
          Text(
            'Pilih Saku (Pocket) Tujuan',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          InkWell(
            onTap: () {
              final list = envelopes.value ?? [];
              if (list.isNotEmpty) {
                _showPocketPicker(context, list);
              }
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selectedPocketId != null
                      ? AppColors.primary
                      : theme.dividerColor.withValues(alpha: 0.15),
                  width: _selectedPocketId != null ? 1.8 : 1.5,
                ),
                boxShadow: _selectedPocketId != null
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
                    LucideIcons.folder,
                    color: _selectedPocketId != null
                        ? AppColors.primary
                        : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getSelectedPocketLabel(envelopes.value ?? []),
                      style: TextStyle(
                        fontWeight: _selectedPocketId != null
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 14.5,
                        color: _selectedPocketId != null
                            ? theme.textTheme.bodyLarge?.color
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronDown,
                    color: _selectedPocketId != null
                        ? AppColors.primary
                        : Colors.grey.shade400,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // 2. Choose Source Account (Only visible for new fresh scans/manual inputs, not existing inbox transactions)
          if (widget.transactionId == null) ...[
            const SizedBox(height: 20),
            Text(
              'Pilih Sumber Dana (Rekening)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                final list = accounts.value ?? [];
                if (list.isNotEmpty) {
                  _showAccountPicker(context, list);
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _selectedAccountId != null
                        ? AppColors.primary
                        : theme.dividerColor.withValues(alpha: 0.15),
                    width: _selectedAccountId != null ? 1.8 : 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.creditCard,
                      color: _selectedAccountId != null
                          ? AppColors.primary
                          : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getSelectedAccountLabel(accounts.value ?? []),
                        style: TextStyle(
                          fontWeight: _selectedAccountId != null
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 14.5,
                          color: _selectedAccountId != null
                              ? theme.textTheme.bodyLarge?.color
                              : Colors.grey.shade500,
                        ),
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronDown,
                      color: _selectedAccountId != null
                          ? AppColors.primary
                          : Colors.grey.shade400,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          // Auto Categorization Checkbox
          CheckboxListTile(
            value: _autoCategorize,
            onChanged: (val) {
              setState(() {
                _autoCategorize = val ?? true;
              });
            },
            title: Text(
              'Selalu masukkan transaksi dari "${widget.merchantName}" ke Saku ini',
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary,
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedPocketId != null && (_selectedAccountId != null || widget.transactionId != null) && !_isSaving)
                  ? _submitAssignment
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Alokasikan Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  String _getSelectedPocketLabel(List<Envelope> envelopeList) {
    if (_selectedPocketId == null) return 'Pilih Saku';
    for (var env in envelopeList) {
      for (var p in env.pockets) {
        if (p.id == _selectedPocketId) {
          return '${env.name} -> ${p.name}';
        }
      }
    }
    return 'Pilih Saku';
  }

  String _getSelectedAccountLabel(List<Account> accountsList) {
    if (_selectedAccountId == null) return 'Pilih Sumber Dana';
    for (var acc in accountsList) {
      if (acc.id == _selectedAccountId) {
        final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
        return '${acc.name} (${formatter.format(acc.balance)})';
      }
    }
    return 'Pilih Sumber Dana';
  }

  void _showPocketPicker(BuildContext context, List<Envelope> envelopeList) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        String searchQuery = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.70,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      'Pilih Saku Tujuan',
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
                      onChanged: (val) => setModalState(() => searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: const Icon(LucideIcons.search, size: 18, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: theme.dividerColor.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: envelopeList.map((env) {
                        final matchingPockets = env.pockets
                            .where((p) => p.name.toLowerCase().contains(searchQuery.toLowerCase()))
                            .toList();

                        if (matchingPockets.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Text(
                                env.name.toUpperCase(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            ...matchingPockets.map((pocket) {
                              final isSel = pocket.id == _selectedPocketId;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: isSel ? pocket.color.withValues(alpha: 0.08) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  leading: Icon(pocket.iconData, color: pocket.color, size: 20),
                                  title: Text(
                                    pocket.name,
                                    style: TextStyle(
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                      color: isSel ? pocket.color : theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  trailing: isSel ? Icon(LucideIcons.check, color: pocket.color, size: 20) : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedPocketId = pocket.id;
                                    });
                                    Navigator.pop(ctx);
                                  },
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                          ],
                        );
                      }).toList(),
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

  void _showAccountPicker(BuildContext context, List<Account> accountsList) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        String searchQuery = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.70,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      'Pilih Sumber Dana',
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
                      onChanged: (val) => setModalState(() => searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: const Icon(LucideIcons.search, size: 18, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: theme.dividerColor.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: accountsList
                          .where((acc) => acc.name.toLowerCase().contains(searchQuery.toLowerCase()))
                          .map((acc) {
                        final isSel = acc.id == _selectedAccountId;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            leading: Icon(LucideIcons.creditCard, color: isSel ? AppColors.primary : Colors.grey, size: 20),
                            title: Text(
                              acc.name,
                              style: TextStyle(
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? AppColors.primary : theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            subtitle: Text(
                              NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(acc.balance),
                              style: TextStyle(
                                fontSize: 12,
                                color: isSel ? AppColors.primary : Colors.grey,
                              ),
                            ),
                            trailing: isSel ? const Icon(LucideIcons.check, color: AppColors.primary, size: 20) : null,
                            onTap: () {
                              setState(() {
                                _selectedAccountId = acc.id;
                              });
                              Navigator.pop(ctx);
                            },
                          ),
                        );
                      }).toList(),
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
