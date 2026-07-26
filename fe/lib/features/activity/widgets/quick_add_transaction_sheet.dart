import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../envelopes/providers/envelope_provider.dart';
import '../../envelopes/models/envelope.dart';
import '../providers/transactions_provider.dart';

// ─── Thousand Separator Formatter ───────────────────────────────────────────
class _ThousandSeparatorFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###', 'id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Strip non-digits
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return const TextEditingValue(text: '');

    final number = int.tryParse(digitsOnly) ?? 0;
    final formatted = _formatter.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ─── Category Model ─────────────────────────────────────────────────────────
class _Category {
  final String name;
  final String emoji;
  final Color color;

  const _Category(this.name, this.emoji, this.color);
}

// ─── Main Sheet Widget ──────────────────────────────────────────────────────
class QuickAddTransactionSheet extends ConsumerStatefulWidget {
  final double? initialAmount;
  final int? initialTab;

  const QuickAddTransactionSheet({
    super.key,
    this.initialAmount,
    this.initialTab,
  });

  @override
  ConsumerState<QuickAddTransactionSheet> createState() =>
      _QuickAddTransactionSheetState();
}

class _QuickAddTransactionSheetState
    extends ConsumerState<QuickAddTransactionSheet>
    with SingleTickerProviderStateMixin {
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _transferToController = TextEditingController();
  late TabController _tabController;

  bool _isSaving = false;

  final List<_Category> _incomeCategories = const [
    _Category('Gaji', '💰', AppColors.primary),
    _Category('Bonus', '🎁', AppColors.accentAmber),
    _Category('Investasi', '📈', Colors.teal),
    _Category('Lainnya', '📦', Colors.grey),
  ];

  // Selected state
  String _selectedCategory = 'Makanan';
  String _selectedCategoryEmoji = '🍕';
  String _selectedAccountType = 'bank';
  String? _selectedAccountId;
  String? _selectedEnvelopeId;
  String? _transferFromId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab ?? 0);
    
    if (widget.initialAmount != null) {
      final formatted = _ThousandSeparatorFormatter().formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: widget.initialAmount!.toInt().toString()),
      ).text;
      _amountController.text = formatted;
    }

    // Set initial category emoji based on tab
    if (widget.initialTab == 1) {
      _selectedCategory = 'Gaji';
      _selectedCategoryEmoji = '💰';
    }

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          final type = _tabController.index;
          if (type == 0) {
            _selectedCategory = 'Makanan';
            _selectedCategoryEmoji = '🍕';
          } else if (type == 1) {
            _selectedCategory = 'Gaji';
            _selectedCategoryEmoji = '💰';
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    _transferToController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  bool _isCashAccount(Account acc) {
    final n = acc.name.toLowerCase();
    return n.contains('tunai') ||
        n.contains('cash') ||
        n.contains('dompet') ||
        n.contains('saku');
  }

  String get _currentType {
    switch (_tabController.index) {
      case 0:
        return 'pengeluaran';
      case 1:
        return 'pemasukan';
      case 2:
        return 'transfer';
      default:
        return 'pengeluaran';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accounts = ref.watch(accountsProvider).value ?? [];
    final envelopes = ref.watch(envelopesProvider).value ?? [];
    final bankAccounts = accounts.where((a) => !_isCashAccount(a)).toList();
    final cashAccounts = accounts.where((a) => _isCashAccount(a)).toList();

    // Auto-select defaults
    if (_selectedAccountId == null && accounts.isNotEmpty) {
      final pool = _selectedAccountType == 'bank' ? bankAccounts : cashAccounts;
      _selectedAccountId = pool.isNotEmpty ? pool.first.id : accounts.first.id;
    }
    if (_selectedEnvelopeId == null && envelopes.isNotEmpty) {
      _selectedEnvelopeId = envelopes.first.id;
    }
    if (_transferFromId == null && bankAccounts.isNotEmpty) {
      _transferFromId = bankAccounts.first.id;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Drag Handle ──────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header Row ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  'Tambahkan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                TextButton(
                  onPressed: _isSaving ? null : _saveTransaction,
                  child: Text(
                    'Simpan',
                    style: TextStyle(
                      color: _isSaving
                          ? theme.disabledColor
                          : AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Type Tabs ────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicatorPadding: const EdgeInsets.all(3),
              labelColor: Colors.white,
              unselectedLabelColor: theme.textTheme.bodyMedium?.color,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Pengeluaran', height: 38),
                Tab(text: 'Pemasukan', height: 38),
                Tab(text: 'Transfer', height: 38),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Body ─────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExpenseTab(
                  theme,
                  accounts,
                  bankAccounts,
                  cashAccounts,
                  envelopes,
                ),
                _buildIncomeTab(theme, accounts, bankAccounts, cashAccounts),
                _buildTransferTab(theme, bankAccounts),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // EXPENSE TAB
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildExpenseTab(
    ThemeData theme,
    List<Account> accounts,
    List<Account> bankAccounts,
    List<Account> cashAccounts,
    List<Envelope> envelopes,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      children: [
        // Amount
        _buildAmountInput(theme, AppColors.error),
        const SizedBox(height: 20),

        // Name
        _buildSectionLabel(theme, 'Keterangan'),
        const SizedBox(height: 8),
        _buildNameInput(theme, 'Misal: makan siang'),
        const SizedBox(height: 24),

        // Account (Source)
        _buildSelectionField(
          theme: theme,
          label: 'Sumber Dana',
          value: _getSelectedAccountName(accounts),
          icon: _getSelectedAccountIcon(accounts),
          color: _getSelectedAccountColor(accounts),
          onTap: () => _showAccountSelectionBottomSheet(
            context,
            bankAccounts,
            cashAccounts,
          ),
        ),
        const SizedBox(height: 24),

        // Envelope / Pocket (Category)
        if (envelopes.isNotEmpty) ...[
          _buildSelectionField(
            theme: theme,
            label: 'Kategori Pengeluaran',
            value: _getSelectedEnvelopeOrPocketName(envelopes),
            icon: _getSelectedEnvelopeOrPocketIcon(envelopes),
            color: _getSelectedEnvelopeOrPocketColor(envelopes),
            onTap: () => _showPocketSelectionBottomSheet(context, envelopes),
          ),
          const SizedBox(height: 24),
        ],

        // Notes
        _buildSectionLabel(theme, 'Catatan (opsional)'),
        const SizedBox(height: 8),
        _buildNotesInput(theme),
        const SizedBox(height: 80),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // INCOME TAB
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildIncomeTab(
    ThemeData theme,
    List<Account> accounts,
    List<Account> bankAccounts,
    List<Account> cashAccounts,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      children: [
        // Amount
        _buildAmountInput(theme, AppColors.primary),
        const SizedBox(height: 20),

        // Category Grid
        _buildSectionLabel(theme, 'Sumber Pemasukan'),
        const SizedBox(height: 12),
        _buildCategoryGrid(theme, _incomeCategories),
        const SizedBox(height: 24),

        // Name
        _buildSectionLabel(theme, 'Keterangan'),
        const SizedBox(height: 8),
        _buildNameInput(theme, 'Contoh: gaji bulan Juli'),
        const SizedBox(height: 24),

        // Account (Target)
        _buildSelectionField(
          theme: theme,
          label: 'Masuk ke Rekening',
          value: _getSelectedAccountName(accounts),
          icon: _getSelectedAccountIcon(accounts),
          color: _getSelectedAccountColor(accounts),
          onTap: () => _showAccountSelectionBottomSheet(
            context,
            bankAccounts,
            cashAccounts,
          ),
        ),
        const SizedBox(height: 24),

        // Notes
        _buildSectionLabel(theme, 'Catatan (opsional)'),
        const SizedBox(height: 8),
        _buildNotesInput(theme),
        const SizedBox(height: 80),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // TRANSFER TAB
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildTransferTab(ThemeData theme, List<Account> bankAccounts) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      children: [
        _buildAmountInput(theme, const Color(0xFF6366F1)),
        const SizedBox(height: 24),

        // From Account
        _buildSectionLabel(theme, 'Dari Rekening'),
        const SizedBox(height: 10),
        _buildAccountChipList(theme, bankAccounts, _transferFromId, (id) {
          setState(() => _transferFromId = id);
        }),
        const SizedBox(height: 24),

        // Transfer arrow visual
        Center(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.arrowDown, color: Color(0xFF6366F1)),
          ),
        ),
        const SizedBox(height: 16),

        // To Account
        _buildSectionLabel(theme, 'Ke Rekening (Tujuan Luar)'),
        const SizedBox(height: 10),
        TextField(
          controller: _transferToController,
          decoration: InputDecoration(
            hintText: 'Contoh: BCA 123456789 a/n Budi',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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
        const SizedBox(height: 24),

        // Name
        _buildSectionLabel(theme, 'Keterangan'),
        const SizedBox(height: 8),
        _buildNameInput(theme, 'Contoh: top up e-wallet'),
        const SizedBox(height: 24),

        // Notes
        _buildSectionLabel(theme, 'Catatan (opsional)'),
        const SizedBox(height: 8),
        _buildNotesInput(theme),
        const SizedBox(height: 80),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // SHARED COMPONENTS
  // ──────────────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 12,
        letterSpacing: 0.3,
        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildAmountInput(ThemeData theme, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Rp',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandSeparatorFormatter(),
              ],
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: accentColor,
                height: 1.1,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '0',
                hintStyle: TextStyle(
                  color: accentColor.withValues(alpha: 0.25),
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameInput(ThemeData theme, String hint) {
    return TextField(
      controller: _nameController,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: theme.disabledColor.withValues(alpha: 0.5),
          fontSize: 14,
        ),
        filled: true,
        fillColor: theme.dividerColor.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildNotesInput(ThemeData theme) {
    return TextField(
      controller: _notesController,
      maxLines: 2,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Tulis catatan tambahan...',
        hintStyle: TextStyle(
          color: theme.disabledColor.withValues(alpha: 0.5),
          fontSize: 13,
        ),
        filled: true,
        fillColor: theme.dividerColor.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(ThemeData theme, List<_Category> categories) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.82,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, idx) {
        final cat = categories[idx];
        final isSel = _selectedCategory == cat.name;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = cat.name;
              _selectedCategoryEmoji = cat.emoji;
            });
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isSel
                      ? cat.color.withValues(alpha: 0.15)
                      : theme.dividerColor.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSel ? cat.color : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(cat.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(height: 6),
              Text(
                cat.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  color: isSel ? cat.color : theme.textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  String _getSelectedAccountName(List<Account> accounts) {
    if (_selectedAccountId == null) return 'Pilih Sumber Dana';
    final matches = accounts.where((a) => a.id == _selectedAccountId);
    if (matches.isNotEmpty) {
      final acc = matches.first;
      final typeText = !_isCashAccount(acc) ? 'Rekening' : 'Tunai';
      return '${acc.name} ($typeText)';
    }
    return 'Pilih Sumber Dana';
  }

  IconData _getSelectedAccountIcon(List<Account> accounts) {
    if (_selectedAccountId == null) return LucideIcons.landmark;
    final matches = accounts.where((a) => a.id == _selectedAccountId);
    if (matches.isNotEmpty) {
      final acc = matches.first;
      return !_isCashAccount(acc) ? LucideIcons.landmark : LucideIcons.wallet;
    }
    return LucideIcons.landmark;
  }

  Color _getSelectedAccountColor(List<Account> accounts) {
    if (_selectedAccountId == null) return Colors.grey;
    final matches = accounts.where((a) => a.id == _selectedAccountId);
    if (matches.isNotEmpty) {
      final acc = matches.first;
      return !_isCashAccount(acc) ? AppColors.primary : AppColors.accentAmber;
    }
    return Colors.grey;
  }

  void _showAccountSelectionBottomSheet(
    BuildContext context,
    List<Account> bankAccounts,
    List<Account> cashAccounts,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final formatter = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        );
        String searchQuery = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredBank = bankAccounts
                .where(
                  (a) =>
                      a.name.toLowerCase().contains(searchQuery.toLowerCase()),
                )
                .toList();
            final filteredCash = cashAccounts
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
                      'Pilih Sumber Dana',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Search Field (Reference: WITH SEARCH)
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

                  // Accounts List with Checkmark (Reference: DROPDOWN SELECTED)
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      children: [
                        if (filteredBank.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              'REKENING BANK',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          ...filteredBank.map((acc) {
                            final isSel = acc.id == _selectedAccountId;
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
                                        ? AppColors.primary.withValues(
                                            alpha: 0.8,
                                          )
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
                                    _selectedAccountId = acc.id;
                                    _selectedAccountType = 'bank';
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                        ],
                        if (filteredCash.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              'TUNAI / DOMPET',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          ...filteredCash.map((acc) {
                            final isSel = acc.id == _selectedAccountId;
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
                                  LucideIcons.wallet,
                                  color: isSel
                                      ? AppColors.primary
                                      : AppColors.accentAmber,
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
                                        ? AppColors.primary.withValues(
                                            alpha: 0.8,
                                          )
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
                                    _selectedAccountId = acc.id;
                                    _selectedAccountType = 'tunai';
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          }),
                        ],
                      ],
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

  String _getSelectedEnvelopeOrPocketName(List<Envelope> envelopes) {
    if (_selectedEnvelopeId == null) return 'Pilih Kategori';
    for (var env in envelopes) {
      if (env.id == _selectedEnvelopeId) {
        return '${env.name} (Utama)';
      }
      for (var p in env.pockets) {
        if (p.id == _selectedEnvelopeId) {
          return '${p.name} (${env.name})';
        }
      }
    }
    return 'Pilih Kategori';
  }

  IconData _getSelectedEnvelopeOrPocketIcon(List<Envelope> envelopes) {
    if (_selectedEnvelopeId == null) return LucideIcons.tag;
    for (var env in envelopes) {
      if (env.id == _selectedEnvelopeId) return env.iconData;
      for (var p in env.pockets) {
        if (p.id == _selectedEnvelopeId) return p.iconData;
      }
    }
    return LucideIcons.tag;
  }

  Color _getSelectedEnvelopeOrPocketColor(List<Envelope> envelopes) {
    if (_selectedEnvelopeId == null) return Colors.grey;
    for (var env in envelopes) {
      if (env.id == _selectedEnvelopeId) return env.color;
      for (var p in env.pockets) {
        if (p.id == _selectedEnvelopeId) return p.color;
      }
    }
    return Colors.grey;
  }

  void _showPocketSelectionBottomSheet(
    BuildContext context,
    List<Envelope> envelopes,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        String searchQuery = '';
        final formatter = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        );

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.70,
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
                      'Pilih Kategori Pengeluaran',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Search Field (Reference: WITH SEARCH)
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
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      children: envelopes.map((env) {
                        final matchingPockets = env.pockets
                            .where(
                              (p) => p.name.toLowerCase().contains(
                                searchQuery.toLowerCase(),
                              ),
                            )
                            .toList();
                        final matchesEnvName = env.name.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        );

                        if (!matchesEnvName && matchingPockets.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final isEnvSel = env.id == _selectedEnvelopeId;
                        final totalPocketAllocated = env.pockets.fold(
                          0.0,
                          (sum, p) => sum + p.allocatedAmount,
                        );
                        double totalNegativePockets = 0.0;
                        for (var p in env.pockets) {
                          if (p.allocatedAmount < 0)
                            totalNegativePockets += p.allocatedAmount.abs();
                        }
                        final rawUnallocated =
                            env.allocatedAmount -
                            totalPocketAllocated -
                            totalNegativePockets;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
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
                            // Master Envelope Option
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: isEnvSel
                                    ? env.color.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                leading: Icon(
                                  env.iconData,
                                  color: env.color,
                                  size: 20,
                                ),
                                title: Text(
                                  '${env.name} (Utama) (${formatter.format(rawUnallocated)})',
                                  style: TextStyle(
                                    fontWeight: isEnvSel
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isEnvSel
                                        ? env.color
                                        : theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                trailing: isEnvSel
                                    ? Icon(
                                        LucideIcons.check,
                                        color: env.color,
                                        size: 20,
                                      )
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedEnvelopeId = env.id;
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                            // Pockets list
                            ...matchingPockets.map((pocket) {
                              final isPocketSel =
                                  pocket.id == _selectedEnvelopeId;
                              return Container(
                                margin: const EdgeInsets.only(
                                  bottom: 4,
                                  left: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: isPocketSel
                                      ? pocket.color.withValues(alpha: 0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  leading: Icon(
                                    pocket.iconData,
                                    color: pocket.color,
                                    size: 20,
                                  ),
                                  title: Text(
                                    '${pocket.name} (${formatter.format(pocket.allocatedAmount)})',
                                    style: TextStyle(
                                      fontWeight: isPocketSel
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isPocketSel
                                          ? pocket.color
                                          : theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  trailing: isPocketSel
                                      ? Icon(
                                          LucideIcons.check,
                                          color: pocket.color,
                                          size: 20,
                                        )
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedEnvelopeId = pocket.id;
                                    });
                                    Navigator.pop(context);
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

  Widget _buildSelectionField({
    required ThemeData theme,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isSelected = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(theme, label),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : theme.dividerColor.withValues(alpha: 0.15),
                width: isSelected ? 1.8 : 1.5,
              ),
              boxShadow: isSelected
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
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 14.5,
                      color: isSelected
                          ? theme.textTheme.bodyLarge?.color
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevronDown,
                  color: isSelected ? AppColors.primary : Colors.grey.shade400,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountChipList(
    ThemeData theme,
    List<Account> accounts,
    String? selectedId,
    void Function(String) onSelect,
  ) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: accounts.map((acc) {
          final isSel = acc.id == selectedId;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(acc.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSel
                      ? const Color(0xFF6366F1).withValues(alpha: 0.1)
                      : theme.dividerColor.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSel
                        ? const Color(0xFF6366F1)
                        : theme.dividerColor.withValues(alpha: 0.12),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  acc.name,
                  style: TextStyle(
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                    color: isSel
                        ? const Color(0xFF6366F1)
                        : theme.textTheme.bodyMedium?.color,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // SAVE LOGIC
  // ──────────────────────────────────────────────────────────────────────
  void _saveTransaction() async {
    // Parse amount from formatted string (remove dots)
    final rawText = _amountController.text.replaceAll('.', '').trim();
    final amount = double.tryParse(rawText) ?? 0.0;

    if (amount <= 0) {
      _showSnack('Nominal harus lebih besar dari 0');
      return;
    }

    String name = _nameController.text.trim();
    if (name.isEmpty) {
      if (_currentType == 'pengeluaran') {
        name = 'Pengeluaran Baru';
      } else if (_currentType == 'transfer') {
        name = 'Transfer Baru';
      } else {
        name = '$_selectedCategoryEmoji $_selectedCategory';
      }
    }
    final notes = _notesController.text.trim();

    setState(() => _isSaving = true);
    bool success = false;

    try {
      if (_currentType == 'pengeluaran') {
        if (_selectedAccountId == null) {
          _showSnack('Pilih rekening sumber dana');
          return;
        }
        success = await ref
            .read(transactionsProvider.notifier)
            .addExpense(
              amount,
              _selectedAccountId!,
              _selectedEnvelopeId,
              name,
              notes,
              null,
            );
      } else if (_currentType == 'pemasukan') {
        if (_selectedAccountId == null) {
          _showSnack('Pilih rekening tujuan');
          return;
        }
        success = await ref
            .read(transactionsProvider.notifier)
            .addIncome(amount, _selectedAccountId!, name, notes);
      } else if (_currentType == 'transfer') {
        final toAccount = _transferToController.text.trim();
        if (_transferFromId == null || toAccount.isEmpty) {
          _showSnack('Isi rekening asal dan rekening tujuan');
          return;
        }

        final ex = await ref
            .read(transactionsProvider.notifier)
            .addExpense(
              amount,
              _transferFromId!,
              null,
              '🔄 Transfer: $name',
              'Transfer ke $toAccount\n$notes',
              null,
            );
        success = ex;
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  LucideIcons.checkCircle2,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text('Transaksi berhasil disimpan'),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      } else if (!success && mounted) {
        _showSnack('Gagal menyimpan. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg) {
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
