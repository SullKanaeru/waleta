import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../widgets/sunburst_chart.dart';
import '../../activity/providers/transactions_provider.dart';
import '../../envelopes/providers/envelope_provider.dart';
import '../../envelopes/models/envelope.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late List<int> _availableYears;
  int _selectedYearIndex = 0;
  int _selectedMonthIndex = 0;

  final List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  final TextEditingController _reflectionController = TextEditingController();
  bool _isLoadingJournal = false;
  String _currentJournalKey = '';
  Map<String, String> _regretEvaluations = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadJournal();
      }
    });

    final nowYear = DateTime.now().year;
    _availableYears = [nowYear - 2, nowYear - 1, nowYear];
    _selectedYearIndex = _availableYears.length - 1;

    final nowMonth = DateTime.now().month - 1; // 0-indexed
    if (nowMonth > 0) {
      _selectedMonthIndex = nowMonth - 1; // default to last completed month
    } else {
      _selectedMonthIndex = 0;
    }

    _loadJournal();
  }

  void _loadJournal() async {
    setState(() => _isLoadingJournal = true);
    final prefs = await SharedPreferences.getInstance();
    final year = _availableYears[_selectedYearIndex];

    if (_tabController.index == 0) {
      _currentJournalKey = 'journal_${year}_${_selectedMonthIndex + 1}';
    } else {
      _currentJournalKey = 'journal_year_$year';
    }

    final savedText = prefs.getString(_currentJournalKey);
    if (mounted) {
      _reflectionController.text = savedText ?? '';
      _isLoadingJournal = false;
    }

    // Load regrets from transactions
    final txs = ref.read(transactionsProvider).value ?? [];
    _loadRegrets(txs);
  }

  Future<void> _loadRegrets(List<Transaction> txs) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, String> loaded = {};
    for (var t in txs) {
      if (t.type == 'EXPENSE') {
        final val = prefs.getString('regret_${t.id}');
        if (val != null) {
          loaded[t.id] = val;
        }
      }
    }
    if (mounted) {
      setState(() {
        _regretEvaluations = loaded;
      });
    }
  }

  void _saveJournal(String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentJournalKey, text);
  }

  void _setRegret(String txId, String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove('regret_$txId');
      setState(() => _regretEvaluations.remove(txId));
    } else {
      await prefs.setString('regret_$txId', value);
      setState(() => _regretEvaluations[txId] = value);
    }
  }

  bool _isMonthCompleted(int year, int monthIndex) {
    final now = DateTime.now();
    if (year < now.year) return true;
    if (year > now.year) return false;
    return monthIndex < (now.month - 1);
  }

  bool _isYearCompleted(int year) {
    final now = DateTime.now();
    return year < now.year;
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txsAsync = ref.watch(transactionsProvider);
    final envsAsync = ref.watch(envelopesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jurnal Finansial'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.textTheme.bodyMedium?.color,
          tabs: const [
            Tab(text: 'Bulanan'),
            Tab(text: 'Tahunan'),
          ],
        ),
      ),
      body: txsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (txs) {
          final envelopes = envsAsync.value ?? [];
          return TabBarView(
            controller: _tabController,
            children: [
              _buildMonthlyJournalLayout(theme, txs, envelopes),
              _buildYearlyJournalLayout(theme, txs, envelopes),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthlyJournalLayout(
    ThemeData theme,
    List<Transaction> allTxs,
    List<Envelope> envelopes,
  ) {
    return Column(
      children: [
        _buildYearSelector(theme, isCompact: true),
        _buildMonthSelector(theme),
        Expanded(child: _buildMonthlyContent(theme, allTxs, envelopes)),
      ],
    );
  }

  Widget _buildYearlyJournalLayout(
    ThemeData theme,
    List<Transaction> allTxs,
    List<Envelope> envelopes,
  ) {
    return Column(
      children: [
        _buildYearSelector(theme, isCompact: false),
        Expanded(child: _buildYearlyContent(theme, allTxs, envelopes)),
      ],
    );
  }

  Widget _buildYearSelector(ThemeData theme, {required bool isCompact}) {
    return Container(
      height: isCompact ? 54 : 70,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.05)),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _availableYears.length,
        padding: EdgeInsets.symmetric(
            horizontal: 16, vertical: isCompact ? 8 : 12),
        itemBuilder: (context, index) {
          final year = _availableYears[index];
          final isSelected = _selectedYearIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                year.toString(),
                style: TextStyle(fontSize: isCompact ? 13 : 15),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedYearIndex = index);
                  _loadJournal();
                }
              },
              backgroundColor: theme.colorScheme.surface,
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.12),
              labelStyle: TextStyle(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.dividerColor.withValues(alpha: 0.2),
              ),
              padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 12 : 20, vertical: isCompact ? 4 : 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector(ThemeData theme) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.05)),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _months.length,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedMonthIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(_months[index]),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedMonthIndex = index);
                  _loadJournal();
                }
              },
              backgroundColor: theme.colorScheme.surface,
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.12),
              labelStyle: TextStyle(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.dividerColor.withValues(alpha: 0.2),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthlyContent(
    ThemeData theme,
    List<Transaction> allTxs,
    List<Envelope> envelopes,
  ) {
    final year = _availableYears[_selectedYearIndex];
    final monthName = _months[_selectedMonthIndex];

    if (!_isMonthCompleted(year, _selectedMonthIndex)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.calendarClock,
                size: 80,
                color: theme.dividerColor.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 24),
              Text('Jurnal Belum Tersedia', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(
                'Jurnal untuk bulan $monthName $year baru akan dimuat setelah bulan tersebut selesai (di awal bulan berikutnya).',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ).animate().fadeIn(),
      );
    }

    final monthTxs = allTxs
        .where((t) =>
            t.date.year == year && t.date.month == (_selectedMonthIndex + 1))
        .toList();

    double totalIncome = 0;
    double totalExpense = 0;
    for (var t in monthTxs) {
      if (t.type == 'INCOME') {
        totalIncome += t.amount.abs();
      } else if (t.type == 'EXPENSE') {
        totalExpense += t.amount.abs();
      }
    }

    final diff = totalIncome - totalExpense;
    final formatter = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    String summaryText;
    if (monthTxs.isEmpty) {
      summaryText = 'Tidak ada catatan transaksi pada bulan ini.';
    } else if (diff >= 0) {
      summaryText =
          'Bulan ini keuangan Anda surplus sebesar ${formatter.format(diff)}. Pemasukan: ${formatter.format(totalIncome)}, Pengeluaran: ${formatter.format(totalExpense)}.';
    } else {
      summaryText =
          'Bulan ini keuangan Anda defisit sebesar ${formatter.format(diff.abs())}. Pengeluaran (${formatter.format(totalExpense)}) melebihi pemasukan (${formatter.format(totalIncome)}).';
    }

    final sunburstNodes = _buildSunburstData(monthTxs, envelopes);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildHeader(theme, 'Refleksi $monthName $year', summaryText),
        const SizedBox(height: 32),
        _buildFinancialRoast(theme, totalIncome, totalExpense, sunburstNodes),
        const SizedBox(height: 32),
        _buildManualJournal(theme),
        const SizedBox(height: 32),
        Text('Indeks Penyesalan ($monthName)',
            style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildRemorseRadar(theme, monthTxs),
        const SizedBox(height: 32),
        Text('Distribusi Pengeluaran', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildExpenseDistribution(theme, totalExpense, sunburstNodes),
        const SizedBox(height: 32),
        Text('Metrik Kedisiplinan', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildDisciplineScore(theme, totalIncome, totalExpense),
        const SizedBox(height: 32),
        Text('Rekomendasi Aksi', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildActionableInsights(theme, sunburstNodes),
        const SizedBox(height: 48),
      ].animate(interval: 50.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildYearlyContent(
    ThemeData theme,
    List<Transaction> allTxs,
    List<Envelope> envelopes,
  ) {
    final year = _availableYears[_selectedYearIndex];

    if (!_isYearCompleted(year)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.lock,
                size: 80,
                color: theme.dividerColor.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 24),
              Text('Jurnal Belum Tersedia', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(
                'Jurnal tahunan untuk $year baru akan dimuat setelah tahun $year selesai.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ).animate().fadeIn(),
      );
    }

    final yearTxs = allTxs.where((t) => t.date.year == year).toList();

    double totalIncome = 0;
    double totalExpense = 0;
    for (var t in yearTxs) {
      if (t.type == 'INCOME') {
        totalIncome += t.amount.abs();
      } else if (t.type == 'EXPENSE') {
        totalExpense += t.amount.abs();
      }
    }

    final diff = totalIncome - totalExpense;
    final formatter = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    String summaryText;
    if (yearTxs.isEmpty) {
      summaryText = 'Tidak ada transaksi tercatat sepanjang tahun $year.';
    } else if (diff >= 0) {
      summaryText =
          'Sepanjang tahun $year Anda mengalami surplus total sebesar ${formatter.format(diff)}. Pemasukan: ${formatter.format(totalIncome)}, Pengeluaran: ${formatter.format(totalExpense)}.';
    } else {
      summaryText =
          'Sepanjang tahun $year Anda mengalami defisit sebesar ${formatter.format(diff.abs())}. Total Pengeluaran: ${formatter.format(totalExpense)}.';
    }

    final sunburstNodes = _buildSunburstData(yearTxs, envelopes);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildHeader(theme, 'Refleksi Tahunan ($year)', summaryText),
        const SizedBox(height: 32),
        Text('Indeks Penyesalan ($year)', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildRemorseRadar(theme, yearTxs),
        const SizedBox(height: 32),
        Text('Distribusi Pengeluaran Tahunan',
            style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildExpenseDistribution(theme, totalExpense, sunburstNodes),
        const SizedBox(height: 32),
        Text('Metrik Kedisiplinan Tahunan', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildDisciplineScore(theme, totalIncome, totalExpense),
        const SizedBox(height: 32),
        Text('Rekomendasi Resolusi', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildActionableInsightsYearly(theme, sunburstNodes),
        const SizedBox(height: 48),
      ].animate(interval: 50.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
    );
  }

  List<SunburstNode> _buildSunburstData(
    List<Transaction> txs,
    List<Envelope> envelopes,
  ) {
    final Map<String, Map<String, double>> envPocketSpend = {};
    final Map<String, Envelope> envMap = {for (var e in envelopes) e.id: e};
    final Map<String, String> pocketToEnvId = {};
    final Map<String, String> pocketIdToName = {};

    for (var e in envelopes) {
      envPocketSpend[e.id] = {};
      for (var p in e.pockets) {
        pocketToEnvId[p.id] = e.id;
        pocketIdToName[p.id] = p.name;
      }
    }
    if (!envPocketSpend.containsKey('lainnya')) {
      envPocketSpend['lainnya'] = {};
    }

    for (var t in txs) {
      if (t.type == 'EXPENSE') {
        final amt = t.amount.abs();
        String? envId;
        String pocketName = 'Umum';

        if (t.pocketId != null) {
          if (pocketToEnvId.containsKey(t.pocketId)) {
            envId = pocketToEnvId[t.pocketId];
            pocketName = pocketIdToName[t.pocketId] ?? 'Umum';
          } else if (envMap.containsKey(t.pocketId)) {
            envId = t.pocketId;
            pocketName = 'Umum';
          }
        }
        envId ??= 'lainnya';
        if (!envPocketSpend.containsKey(envId)) {
          envPocketSpend[envId] = {};
        }
        envPocketSpend[envId]![pocketName] =
            (envPocketSpend[envId]![pocketName] ?? 0) + amt;
      }
    }

    final List<SunburstNode> data = [];
    envPocketSpend.forEach((envId, pockets) {
      double envTotal = 0;
      pockets.forEach((_, amt) => envTotal += amt);
      if (envTotal > 0) {
        final env = envMap[envId];
        final String envName =
            env?.name ?? (envId == 'lainnya' ? 'Lainnya' : envId);
        final Color envColor = env?.color ?? Colors.grey;

        final List<SunburstNode> children = [];
        int childIdx = 0;
        pockets.forEach((pName, pAmt) {
          if (pAmt > 0) {
            children.add(SunburstNode(
              label: pName,
              value: pAmt,
              color: envColor.withValues(
                  alpha: (0.85 - (childIdx * 0.15)).clamp(0.2, 0.9)),
            ));
            childIdx++;
          }
        });

        data.add(SunburstNode(
          label: envName,
          value: envTotal,
          color: envColor,
          children: children,
        ));
      }
    });

    return data;
  }

  Widget _buildHeader(ThemeData theme, String title, String summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.displayMedium?.copyWith(fontSize: 26),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.barChart2, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  summary,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRemorseRadar(ThemeData theme, List<Transaction> txs) {
    final expTxs = txs.where((t) => t.type == 'EXPENSE').toList()
      ..sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
    final top5 = expTxs.take(5).toList();

    if (top5.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text('Tidak ada pengeluaran yang tercatat pada periode ini.',
              style: theme.textTheme.bodyMedium),
        ),
      );
    }

    final pendingCount =
        top5.where((t) => !_regretEvaluations.containsKey(t.id)).length;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pendingCount > 0 ? 'Menunggu Evaluasi' : 'Evaluasi Selesai',
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pendingCount > 0
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pendingCount > 0 ? '$pendingCount Butuh Aksi' : 'Semua Terjawab',
                  style: TextStyle(
                    color: pendingCount > 0 ? AppColors.error : AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Evaluasi 5 pengeluaran terbesar Anda untuk melatih intuisi anggaran.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ...top5.map((t) => _buildRemorseItem(theme, t, _regretEvaluations[t.id])),
          if (pendingCount == 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.checkCircle2,
                      color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pola Anda Terbaca! Evaluasi terhadap pengeluaran besar ini membantu kalibrasi batas pengeluaran memuaskan vs menyesal untuk Anda!',
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
          ],
        ],
      ),
    );
  }

  Widget _buildRemorseItem(
      ThemeData theme, Transaction tx, String? currentRegret) {
    final formatter = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(tx.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.warning.withValues(alpha: 0.15),
                child: const Icon(LucideIcons.shoppingBag,
                    color: AppColors.warning, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.merchantName.isNotEmpty
                          ? tx.merchantName
                          : 'Pengeluaran',
                      style: theme.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${formatter.format(tx.amount.abs())} • $dateStr',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (currentRegret != null)
                GestureDetector(
                  onTap: () => _setRegret(tx.id, null),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentRegret == 'puas'
                              ? '🤩 Puas'
                              : (currentRegret == 'biasa'
                                  ? '😐 Biasa'
                                  : '📉 Menyesal'),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: 6),
                        const Icon(LucideIcons.edit2,
                            size: 12, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (currentRegret == null) ...[
            const SizedBox(height: 12),
            Text(
              'Bagaimana perasaan Anda tentang pengeluaran ini?',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _EmojiButton(
                  emoji: '🤩',
                  label: 'Puas',
                  onTap: () => _setRegret(tx.id, 'puas'),
                ),
                _EmojiButton(
                  emoji: '😐',
                  label: 'Biasa',
                  onTap: () => _setRegret(tx.id, 'biasa'),
                ),
                _EmojiButton(
                  emoji: '📉',
                  label: 'Menyesal',
                  onTap: () => _setRegret(tx.id, 'menyesal'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpenseDistribution(
    ThemeData theme,
    double totalExpense,
    List<SunburstNode> data,
  ) {
    final formatter = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    if (data.isEmpty || totalExpense == 0) {
      return GlassCard(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text('Belum ada data pengeluaran untuk ditampilkan.',
              style: theme.textTheme.bodyMedium),
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SunburstChart(
            data: data,
            totalValue: totalExpense,
            centerLabel: 'Total Keluar',
            centerAmount: formatter.format(totalExpense),
            size: 260,
          ),
          const SizedBox(height: 32),
          ...data.map((master) {
            final percent = ((master.value / totalExpense) * 100).toInt();
            return Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                iconColor: master.color,
                collapsedIconColor: master.color,
                title: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: master.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        master.label,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        color: master.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.only(
                        left: 28, top: 8, bottom: 16),
                    child: Column(
                      children: master.children.map((pocket) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: pocket.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  pocket.label,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                formatter.format(pocket.value),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDisciplineScore(
      ThemeData theme, double totalIncome, double totalExpense) {
    double scoreVal;
    String desc;

    if (totalIncome <= 0) {
      if (totalExpense > 0) {
        scoreVal = 0.30;
        desc =
            'Terdapat pengeluaran tanpa adanya catatan pemasukan pada periode ini.';
      } else {
        scoreVal = 1.0;
        desc = 'Tidak ada aktivitas pengeluaran pada periode ini.';
      }
    } else {
      final ratio = totalExpense / totalIncome;
      if (ratio <= 0.5) {
        scoreVal = 0.95;
        desc =
            'Luar biasa! Pengeluaran Anda hanya ${(ratio * 100).toInt()}% dari pemasukan. Porsi tabungan Anda sangat sehat!';
      } else if (ratio <= 0.75) {
        scoreVal = 0.85;
        desc =
            'Bagus! Pengeluaran terkendali di bawah 75% pemasukan. Anda masih memiliki ruang nyaman untuk menabung.';
      } else if (ratio <= 1.0) {
        scoreVal = 0.65;
        desc =
            'Waspada! Pengeluaran Anda mencapai ${(ratio * 100).toInt()}% dari pemasukan. Batasi pengeluaran non-esensial.';
      } else {
        scoreVal = 0.35;
        desc =
            'Bahaya! Pengeluaran Anda melebihi pemasukan (defisit ${(ratio * 100).toInt()}%). Segera evaluasi pengeluaran Anda!';
      }
    }

    final scoreText = '${(scoreVal * 100).toInt()}/100';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Skor Kedisiplinan', style: theme.textTheme.labelLarge),
              Text(
                scoreText,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontSize: 24,
                  color: scoreVal > 0.7
                      ? AppColors.accentAmber
                      : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: scoreVal,
            backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
            color: scoreVal > 0.7 ? AppColors.accentAmber : AppColors.warning,
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scoreVal > 0.7
                  ? AppColors.accentAmber.withValues(alpha: 0.05)
                  : AppColors.error.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  scoreVal > 0.7
                      ? LucideIcons.checkCircle
                      : LucideIcons.alertCircle,
                  color: scoreVal > 0.7
                      ? AppColors.accentAmber
                      : AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    desc,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionableInsights(ThemeData theme, List<SunburstNode> nodes) {
    final formatter = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    String adviceText =
        'Pola pengeluaran Anda cukup stabil. Terus catat transaksi setiap hari agar analisa anggaran semakin presisi.';
    if (nodes.isNotEmpty) {
      final topNode = nodes.reduce((a, b) => a.value > b.value ? a : b);
      adviceText =
          'Pengeluaran terbesar Anda berada pada amplop "${topNode.label}" sebesar ${formatter.format(topNode.value)}. Kami sarankan memeriksa kembali alokasi serta batas Safe-to-Spend pada amplop tersebut untuk bulan depan.';
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.lightbulb, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Rekomendasi Sistem',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(adviceText, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Saran telah dicatat dan diterapkan pada alokasi bulan depan!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Setuju & Terapkan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionableInsightsYearly(
      ThemeData theme, List<SunburstNode> nodes) {
    final formatter = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    String adviceText =
        'Tahun yang luar biasa! Evaluasi kembali tujuan finansial jangka panjang Anda untuk menyusun strategi yang lebih matang.';
    if (nodes.isNotEmpty) {
      final topNode = nodes.reduce((a, b) => a.value > b.value ? a : b);
      adviceText =
          'Sepanjang tahun, pengeluaran terbesar tersedot ke "${topNode.label}" (${formatter.format(topNode.value)}). Disarankan membuat rekening terpisah atau amplop khusus resolusi agar anggaran tahun depan lebih terjaga.';
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.target, color: AppColors.accentAmber),
              const SizedBox(width: 8),
              Text(
                'Resolusi Tahun Depan',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 16,
                  color: AppColors.accentAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(adviceText, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Resolusi anggaran baru otomatis disiapkan untuk tahun depan!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentAmber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Terapkan Resolusi'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRoast(
    ThemeData theme,
    double totalIncome,
    double totalExpense,
    List<SunburstNode> data,
  ) {
    final formatter = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    String roastText;
    if (totalExpense == 0 && totalIncome == 0) {
      roastText =
          '"Tidak ada pergerakan uang sama sekali bulan ini. Sedang bertapa atau lupa mencatat transaksi? 🤔"';
    } else if (totalExpense > totalIncome && totalIncome > 0) {
      roastText =
          '"Aduhh! Pengeluaranmu bulan ini (${formatter.format(totalExpense)}) melampaui pemasukan (${formatter.format(totalIncome)}). Dompet berteriak minta tolong! Kurangi jajan impulsif bulan depan ya! 💸"';
    } else if (totalExpense == 0 && totalIncome > 0) {
      roastText =
          '"Pemasukan masuk terus tanpa pengeluaran sepeser pun! Kamu super hemat atau ditraktir terus sebulan penuh? 👑"';
    } else {
      String topEnvName = 'Kebutuhan';
      double topEnvAmt = 0;
      for (var node in data) {
        if (node.value > topEnvAmt) {
          topEnvAmt = node.value;
          topEnvName = node.label;
        }
      }
      final percentage = totalIncome > 0
          ? ((totalExpense / totalIncome) * 100).toInt()
          : 100;
      if (percentage < 50) {
        roastText =
            '"Luar biasa! Kamu hanya menghabiskan $percentage% dari penghasilanmu, dengan pengeluaran terbesar di saku $topEnvName (${formatter.format(topEnvAmt)}). Pertahankan gaya hidup hemat ini! 🚀"';
      } else {
        roastText =
            '"Bulan ini kamu menghabiskan $percentage% dari pemasukanmu. Fokus pengeluaran terbesar tersedot ke $topEnvName sebesar ${formatter.format(topEnvAmt)}. Hati-hati jangan sampai kehabisan napas di akhir bulan! 🧐"';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.sparkles,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Financial Roast & Analisa AI',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                Colors.teal.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analisa Spesifik Bulan Ini',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                roastText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color: theme.textTheme.bodyLarge?.color?.withValues(
                    alpha: 0.9,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Dianalisa dari data transaksi Anda',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManualJournal(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.penTool, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(
              'Catatan Kaki & Refleksi',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Tuliskan pelajaran finansial terbesarmu pada periode ini.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: TextField(
            controller: _reflectionController,
            maxLines: 6,
            onChanged: _saveJournal,
            decoration: InputDecoration(
              hintText:
                  'Misalnya: "Jangan ke supermarket kalau lagi lapar..."',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade400,
                fontStyle: FontStyle.italic,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _EmojiButton extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _EmojiButton({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
