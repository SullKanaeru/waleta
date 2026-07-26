import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../widgets/sunburst_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Asumsikan saat ini adalah bulan Agustus (indeks 7), sehingga Juli (indeks 6) baru saja ditutup.
  final int _currentMonthIndex = 7;

  // State untuk bulan yang dipilih pengguna di Tab Bulanan
  int _selectedMonthIndex = 6;

  // Status review per bulan (mock: Juli masih pending, Juni sudah selesai)
  final Map<int, String> _reviewStatusMap = {
    5: 'reviewed', // Juni
    6: 'pending', // Juli
  };

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

  String _reviewStatusYearly = 'pending';

  final int _currentYear = 2026;
  final List<int> _availableYears = [2024, 2025, 2026];
  int _selectedYearIndex = 2; // Default to 2026

  final TextEditingController _reflectionController = TextEditingController();
  bool _isLoadingJournal = false;
  String _currentJournalKey = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadJournal();
  }

  void _loadJournal() async {
    final prefs = await SharedPreferences.getInstance();
    _currentJournalKey = 'journal_$_currentYear-${_selectedMonthIndex + 1}';
    final savedText = prefs.getString(_currentJournalKey);
    if (savedText != null && mounted) {
      _reflectionController.text = savedText;
    }
    if (mounted) setState(() => _isLoadingJournal = false);
  }

  void _saveJournal(String text) async {
    final prefs = await SharedPreferences.getInstance();
    _currentJournalKey = 'journal_$_currentYear-${_selectedMonthIndex + 1}';
    await prefs.setString(_currentJournalKey, text);
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMonthlyJournalLayout(theme),
          _buildYearlyJournalLayout(theme),
        ],
      ),
    );
  }

  Widget _buildMonthlyJournalLayout(ThemeData theme) {
    return Column(
      children: [
        _buildMonthSelector(theme),
        Expanded(child: _buildMonthlyContent(theme)),
      ],
    );
  }

  Widget _buildYearlyJournalLayout(ThemeData theme) {
    return Column(
      children: [
        _buildYearSelector(theme),
        Expanded(child: _buildYearlyContent(theme)),
      ],
    );
  }

  Widget _buildMonthSelector(ThemeData theme) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.05)),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _months.length,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.1),
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

  Widget _buildYearSelector(ThemeData theme) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.05)),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _availableYears.length,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemBuilder: (context, index) {
          final year = _availableYears[index];
          final isSelected = _selectedYearIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ChoiceChip(
              label: Text(
                year.toString(),
                style: const TextStyle(fontSize: 16),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedYearIndex = index);
              },
              backgroundColor: theme.colorScheme.surface,
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.1),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthlyContent(ThemeData theme) {
    if (_selectedMonthIndex >= _currentMonthIndex) {
      // Future or current month (not finished yet)
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
                'Jurnal untuk bulan ${_months[_selectedMonthIndex]} baru akan dimuat setelah bulan tersebut usai (di awal bulan berikutnya).',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ).animate().fadeIn(),
      );
    }

    final isJuly = _selectedMonthIndex == 6;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildHeader(
          theme,
          'Refleksi ${_months[_selectedMonthIndex]}',
          isJuly
              ? 'Minggu pertama cukup impulsif, tapi minggu ketiga Anda sangat hemat! Selesaikan evaluasi tertunda Anda di bawah.'
              : 'Bulan ini sangat stabil. Anda berhasil mencapai semua target tabungan harian.',
        ),
        const SizedBox(height: 32),
        _buildFinancialRoast(theme),
        const SizedBox(height: 32),
        _buildManualJournal(theme),
        const SizedBox(height: 32),
        Text(
          'Indeks Penyesalan (${_months[_selectedMonthIndex]})',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        _buildRemorseRadar(
          theme,
          isYearly: false,
          monthIndex: _selectedMonthIndex,
        ),
        const SizedBox(height: 32),
        Text('Distribusi Pengeluaran', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildExpenseDistribution(theme, isYearly: false),
        const SizedBox(height: 32),
        Text('Metrik Kedisiplinan', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildDisciplineScore(
          theme,
          isJuly ? '65/100' : '90/100',
          isJuly ? 0.65 : 0.90,
          isJuly
              ? 'Bulan ini Anda 3 kali memecah Amplop "Tabungan" untuk menutupi "Kebutuhan".'
              : 'Hebat! Anda tidak pernah menyentuh dana darurat untuk kebutuhan harian sepanjang bulan.',
        ),
        const SizedBox(height: 32),
        Text('Rekomendasi Aksi', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildActionableInsights(theme),
        const SizedBox(height: 48),
      ].animate(interval: 50.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildYearlyContent(ThemeData theme) {
    final year = _availableYears[_selectedYearIndex];
    if (year >= _currentYear) {
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
                'Jurnal tahunan untuk $year baru akan dibuat dan dapat dievaluasi ketika tahun $year telah usai.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ).animate().fadeIn(),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildHeader(
          theme,
          'Refleksi Tahunan ($year)',
          'Tahun ini merangkum pergerakan bulanan Anda. Bulan Juli adalah bulan terboros, sedangkan April Anda berhasil menabung paling banyak!',
        ),
        const SizedBox(height: 32),
        Text('Indeks Penyesalan ($year)', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildRemorseRadar(theme, isYearly: true, monthIndex: -1),
        const SizedBox(height: 32),
        Text('Distribusi Pengeluaran', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildExpenseDistribution(theme, isYearly: true),
        const SizedBox(height: 32),
        Text('Metrik Kedisiplinan Tahunan', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildDisciplineScore(
          theme,
          '82/100',
          0.82,
          'Secara keseluruhan tahun ini Anda sangat disiplin! Hanya di bulan Juli dan Desember saja Anda sedikit lengah.',
        ),
        const SizedBox(height: 32),
        Text('Rekomendasi Resolusi', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildActionableInsightsYearly(theme),
        const SizedBox(height: 48),
      ].animate(interval: 50.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildHeader(ThemeData theme, String title, String summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.displayMedium?.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
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

  Widget _buildRemorseRadar(
    ThemeData theme, {
    required bool isYearly,
    required int monthIndex,
  }) {
    final status = isYearly
        ? _reviewStatusYearly
        : _reviewStatusMap[monthIndex] ?? 'reviewed';

    final setStatus = isYearly
        ? () => setState(() => _reviewStatusYearly = 'reviewed')
        : () => setState(() => _reviewStatusMap[monthIndex] = 'reviewed');

    final successText = isYearly
        ? 'Tahun ini Anda menghabiskan Rp8.000.000 untuk Keinginan, tapi 40% dari transaksi tersebut ternyata Anda tandai dengan "Menyesal".'
        : '90% transaksi bulan ini memuaskan. Evaluasi Anda sangat membantu kalibrasi batas pengeluaran bulan depan!';

    final warningColor = isYearly ? AppColors.error : AppColors.primary;
    final warningIcon = isYearly
        ? LucideIcons.trendingDown
        : LucideIcons.trendingUp;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                status == 'pending' ? 'Menunggu Evaluasi' : 'Evaluasi Selesai',
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
              ),
              if (status == 'pending')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '1 Butuh Aksi',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (status == 'pending')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.warning,
                        child: Icon(
                          LucideIcons.shoppingBag,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isYearly
                                  ? 'Liburan Mendadak (Okt)'
                                  : 'Sepatu Sneakers X',
                              style: theme.textTheme.labelLarge,
                            ),
                            Text(
                              isYearly
                                  ? 'Rp 4.500.000 • Tabungan'
                                  : 'Rp 1.500.000 • Keinginan',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bagaimana perasaan Anda tentang pengeluaran ini?',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _EmojiButton(
                        emoji: '🤩',
                        label: 'Puas',
                        onTap: setStatus,
                      ),
                      _EmojiButton(
                        emoji: '😐',
                        label: 'Biasa',
                        onTap: setStatus,
                      ),
                      _EmojiButton(
                        emoji: '📉',
                        label: 'Menyesal',
                        onTap: setStatus,
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn()
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(warningIcon, color: warningColor, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Pola Anda Terbaca!',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: warningColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    successText,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ).animate().scale(),
        ],
      ),
    );
  }

  Widget _buildExpenseDistribution(ThemeData theme, {required bool isYearly}) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Mock Data for Sunburst Chart
    final total = isYearly ? 120000000.0 : 10000000.0;

    final data = [
      SunburstNode(
        label: 'Kebutuhan',
        value: total * 0.45, // 45%
        color: AppColors.primary,
        children: [
          SunburstNode(
            label: 'Makan',
            value: total * 0.20,
            color: AppColors.primary.withValues(alpha: 0.8),
          ),
          SunburstNode(
            label: 'Transport',
            value: total * 0.15,
            color: AppColors.primary.withValues(alpha: 0.6),
          ),
          SunburstNode(
            label: 'Listrik & Air',
            value: total * 0.10,
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
        ],
      ),
      SunburstNode(
        label: 'Keinginan',
        value: total * 0.35, // 35%
        color: AppColors.warning,
        children: [
          SunburstNode(
            label: 'Jajan Kopi',
            value: total * 0.15,
            color: AppColors.warning.withValues(alpha: 0.8),
          ),
          SunburstNode(
            label: 'Nonton',
            value: total * 0.10,
            color: AppColors.warning.withValues(alpha: 0.6),
          ),
          SunburstNode(
            label: 'Belanja Online',
            value: total * 0.10,
            color: AppColors.warning.withValues(alpha: 0.4),
          ),
        ],
      ),
      SunburstNode(
        label: 'Tabungan',
        value: total * 0.20, // 20%
        color: AppColors.accent,
        children: [
          SunburstNode(
            label: 'Dana Darurat',
            value: total * 0.15,
            color: AppColors.accent.withValues(alpha: 0.8),
          ),
          SunburstNode(
            label: 'Investasi',
            value: total * 0.05,
            color: AppColors.accent.withValues(alpha: 0.6),
          ),
        ],
      ),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SunburstChart(
            data: data,
            totalValue: total,
            centerLabel: 'Pemasukan',
            centerAmount: formatter.format(total),
            size: 260,
          ),
          const SizedBox(height: 32),
          // Accordion for Top-Down approach
          ...data.map((master) {
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
                      '${((master.value / total) * 100).toInt()}%',
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
                      left: 28,
                      top: 8,
                      bottom: 16,
                    ),
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
    ThemeData theme,
    String scoreText,
    double scoreVal,
    String desc,
  ) {
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
                  color: scoreVal > 0.7 ? AppColors.accent : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: scoreVal,
            backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
            color: scoreVal > 0.7 ? AppColors.accent : AppColors.warning,
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scoreVal > 0.7
                  ? AppColors.accent.withValues(alpha: 0.05)
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
                  color: scoreVal > 0.7 ? AppColors.accent : AppColors.error,
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

  Widget _buildActionableInsights(ThemeData theme) {
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
                'Auto-Correction',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Bulan lalu batas Safe-to-Spend Kebutuhan Anda selalu kritis di minggu ketiga. Kami sarankan naikkan alokasi gaji dari rekening Mandiri ke Amplop Kebutuhan dari 50% menjadi 60%.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Aturan Sweeping berhasil diperbarui untuk bulan depan!',
                    ),
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
              child: const Text('Setuju & Update Otomatis'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionableInsightsYearly(ThemeData theme) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.target, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                'Resolusi 2027',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 16,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Berdasarkan rasio penyesalan dari liburan mendadak dan transportasi. Sistem mengusulkan pembuatan "Amplop Healing" khusus sebesar 15% dari pendapatan agar tahun depan liburan tidak mengganggu tabungan inti.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Amplop Healing otomatis dibuat untuk 2027!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
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

  Widget _buildFinancialRoast(ThemeData theme) {
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
              'Financial Roast (AI)',
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
                'Analisis AI Bulan Ini',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '"Bulan ini, kamu berhasil menekan pengeluaran di dompet Keinginan hingga sisa Rp 300.000. Hebat! Tapi hati-hati, frekuensi jajan di saku \'Kopi\' naik 40% dari minggu lalu. Yuk, kurangi sedikit minggu depan! 😉"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color: theme.textTheme.bodyLarge?.color?.withValues(
                    alpha: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Dibuat oleh AI',
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
          'Tuliskan pelajaran finansial terbesarmu bulan ini.',
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
            maxLines: 8,
            onChanged: _saveJournal,
            decoration: InputDecoration(
              hintText: 'Misalnya: "Jangan ke supermarket kalau lagi lapar..."',
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
            child: Text(emoji, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
