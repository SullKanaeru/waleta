import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../activity/providers/transactions_provider.dart';

import '../../envelopes/providers/envelope_provider.dart';
import '../../envelopes/models/envelope.dart';
import '../widgets/expense_tab.dart';

class ChartSlice {
  final String label;
  final double value;
  final Color color;

  ChartSlice({required this.label, required this.value, required this.color});
}

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + offset,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final merchantColors = [
    Colors.red.shade400,
    Colors.orange.shade400,
    Colors.amber.shade400,
    Colors.green.shade400,
    Colors.teal.shade400,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionsAsync = ref.watch(transactionsProvider);
    final envelopesAsync = ref.watch(envelopesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.book, size: 20),
            onPressed: () => context.push('/journal'),
            tooltip: 'Jurnal',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: theme.disabledColor,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Pendapatan'),
            Tab(text: 'Pengeluaran'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Month navigator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _changeMonth(-1),
                  child: Icon(
                    LucideIcons.chevronLeft,
                    size: 18,
                    color: theme.disabledColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('MMM yyyy').format(_selectedDate),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _changeMonth(1),
                  child: Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: theme.disabledColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (transactions) {
                final currentMonthTx = transactions.where((t) {
                  return t.date.year == _selectedDate.year &&
                      t.date.month == _selectedDate.month;
                }).toList();

                final incomeTx = currentMonthTx
                    .where((t) => t.type == 'INCOME')
                    .toList();
                final expenseTx = currentMonthTx
                    .where((t) => t.type == 'EXPENSE')
                    .toList();

                // Prepare Pendapatan Slices
                double totalIncome = 0;
                final Map<String, double> incomeByMerchant = {};
                for (var tx in incomeTx) {
                  totalIncome += tx.amount;
                  final key = tx.merchantName.isEmpty
                      ? 'Lainnya'
                      : tx.merchantName;
                  incomeByMerchant[key] =
                      (incomeByMerchant[key] ?? 0) + tx.amount;
                }
                final incomeSlices = incomeByMerchant.entries.map((e) {
                  final idx = incomeByMerchant.keys.toList().indexOf(e.key);
                  return ChartSlice(
                    label: e.key,
                    value: e.value,
                    color: merchantColors[idx % merchantColors.length],
                  );
                }).toList();
                incomeSlices.sort((a, b) => b.value.compareTo(a.value));

                // Prepare Pengeluaran Slices (Inner: Envelope, Outer: Pocket)
                final List<ChartSlice> innerExpenseSlices = [];
                final List<ChartSlice> outerExpenseSlices = [];

                if (envelopesAsync.hasValue) {
                  final envelopes = envelopesAsync.value!;
                  final pocketIdToEnvelope = <String, Envelope>{};
                  final pocketIdToPocket = <String, Pocket>{};

                  for (var env in envelopes) {
                    pocketIdToEnvelope[env.id] = env;
                    for (var pocket in env.pockets) {
                      pocketIdToEnvelope[pocket.id] = env;
                      pocketIdToPocket[pocket.id] = pocket;
                    }
                  }

                  final expenseByEnvelope = <String, double>{};
                  final expenseByPocketInsideEnv =
                      <String, Map<String, double>>{};

                  for (var tx in expenseTx) {
                    final amt = tx.amount.abs();
                    final pId = tx.pocketId;
                    final env = (pId != null) ? pocketIdToEnvelope[pId] : null;
                    final envId = env?.id ?? 'Lainnya';

                    expenseByEnvelope[envId] =
                        (expenseByEnvelope[envId] ?? 0) + amt;
                    expenseByPocketInsideEnv.putIfAbsent(envId, () => {});

                    final innerPId = pId ?? 'Lainnya';
                    expenseByPocketInsideEnv[envId]![innerPId] =
                        (expenseByPocketInsideEnv[envId]![innerPId] ?? 0) + amt;
                  }

                  final sortedEnvEntries = expenseByEnvelope.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  for (var envEntry in sortedEnvEntries) {
                    final envId = envEntry.key;
                    final envAmt = envEntry.value;

                    final env = (envId == 'Lainnya')
                        ? null
                        : pocketIdToEnvelope[envId];
                    final envName = env?.name ?? 'Lainnya';

                    Color envColor = env?.color ?? Colors.grey.shade500;

                    innerExpenseSlices.add(
                      ChartSlice(
                        label: envName,
                        value: envAmt,
                        color: envColor,
                      ),
                    );

                    final pocketsInEnv = expenseByPocketInsideEnv[envId]!;
                    final sortedPocketEntries = pocketsInEnv.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                    int pocketIndex = 0;
                    final totalPockets = sortedPocketEntries.length;
                    final envHsl = HSLColor.fromColor(envColor);

                    for (var pEntry in sortedPocketEntries) {
                      final pId = pEntry.key;
                      final pAmt = pEntry.value;
                      final isEnvelopeId = pId == envId;
                      final pocket = pocketIdToPocket[pId];

                      final pName =
                          pocket?.name ??
                          (isEnvelopeId && env != null
                              ? 'Lain-lain (${env.name})'
                              : 'Lainnya');

                      double minLightness = (envHsl.lightness + 0.12).clamp(
                        0.1,
                        0.85,
                      );
                      double maxLightness = 0.90;

                      bool shiftDarker = envHsl.lightness > 0.65;
                      if (shiftDarker) {
                        minLightness = (envHsl.lightness - 0.12).clamp(
                          0.15,
                          0.9,
                        );
                        maxLightness = 0.20;
                      }

                      double step = totalPockets <= 1
                          ? 0.0
                          : (maxLightness - minLightness) / (totalPockets - 1);
                      double newLightness =
                          (minLightness + (pocketIndex * step)).clamp(
                            0.15,
                            0.95,
                          );
                      double newHue = (envHsl.hue + (pocketIndex * 2)) % 360;

                      final pColor = envHsl
                          .withLightness(newLightness)
                          .withHue(newHue)
                          .toColor();

                      outerExpenseSlices.add(
                        ChartSlice(label: pName, value: pAmt, color: pColor),
                      );
                      pocketIndex++;
                    }
                  }
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabContent(
                      totalIncome,
                      [],
                      incomeSlices,
                      'Pendapatan',
                      theme,
                    ),
                    ExpenseTab(
                      expenseTx: expenseTx,
                      envelopes: envelopesAsync.value ?? [],
                      theme: theme,
                      selectedDate: _selectedDate,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    double total,
    List<ChartSlice> innerSlices,
    List<ChartSlice> outerSlices,
    String type,
    ThemeData theme,
  ) {
    if (total == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.pieChart, size: 48, color: theme.disabledColor),
            const SizedBox(height: 12),
            Text(
              'Belum ada data $type bulan ini',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    final hasInnerLayer = innerSlices.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Chart
          SizedBox(
            height: 260,
            width: double.infinity,
            child: CustomPaint(
              painter: _DonutChartPainter(
                innerSlices: innerSlices,
                outerSlices: outerSlices,
                total: total,
                theme: theme,
                centerLabel: type,
                centerValue: formatter.format(total),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Legend
          if (hasInnerLayer) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kategori', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: innerSlices.map((slice) {
                      final pct = (slice.value / total * 100);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: slice.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${slice.label} ${pct.toStringAsFixed(0)}%',
                            style: theme.textTheme.labelMedium,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Detail list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detail $type', style: theme.textTheme.titleSmall),
                const SizedBox(height: 12),
                ...outerSlices.map((slice) {
                  final pct = (slice.value / total * 100);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: slice.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            slice.label,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: slice.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<ChartSlice> innerSlices;
  final List<ChartSlice> outerSlices;
  final double total;
  final ThemeData theme;
  final String centerLabel;
  final String centerValue;

  _DonutChartPainter({
    required this.innerSlices,
    required this.outerSlices,
    required this.total,
    required this.theme,
    required this.centerLabel,
    required this.centerValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final isTwoLayer = innerSlices.isNotEmpty;

    final outerRadius = size.height / 2.3;
    final outerThickness = isTwoLayer ? size.height / 7 : size.height / 5;
    final outerCenterRadius = outerRadius - outerThickness / 2;

    final innerRadius = outerRadius - outerThickness - 2;
    final innerThickness = size.height / 9;
    final innerCenterRadius = innerRadius - innerThickness / 2;

    if (isTwoLayer) {
      _drawLayer(
        canvas,
        center,
        innerSlices,
        innerCenterRadius,
        innerThickness,
      );
    }

    _drawLayer(canvas, center, outerSlices, outerCenterRadius, outerThickness);
    _drawCallouts(canvas, center, outerSlices, outerRadius);
    _drawCenterText(canvas, center, innerRadius - innerThickness - 4);
  }

  void _drawCenterText(Canvas canvas, Offset center, double maxRadius) {
    if (maxRadius <= 0) return;

    final labelPainter = TextPainter(
      text: TextSpan(
        text: '$centerLabel\n',
        style: TextStyle(
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(
            text: centerValue,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    labelPainter.layout(maxWidth: maxRadius * 2);
    labelPainter.paint(
      canvas,
      Offset(
        center.dx - labelPainter.width / 2,
        center.dy - labelPainter.height / 2,
      ),
    );
  }

  void _drawLayer(
    Canvas canvas,
    Offset center,
    List<ChartSlice> slices,
    double radius,
    double thickness,
  ) {
    double startAngle = -pi / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;

    final gapPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = theme.scaffoldBackgroundColor
      ..strokeWidth = 2.0;

    for (var slice in slices) {
      final sweepAngle = (slice.value / total) * 2 * pi;
      paint.color = slice.color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      final endAngle = startAngle + sweepAngle;
      final x1 = center.dx + (radius - thickness / 2) * cos(endAngle);
      final y1 = center.dy + (radius - thickness / 2) * sin(endAngle);
      final x2 = center.dx + (radius + thickness / 2) * cos(endAngle);
      final y2 = center.dy + (radius + thickness / 2) * sin(endAngle);

      if (slices.length > 1) {
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), gapPaint);
      }

      startAngle += sweepAngle;
    }
  }

  void _drawCallouts(
    Canvas canvas,
    Offset center,
    List<ChartSlice> slices,
    double outerRadius,
  ) {
    double startAngle = -pi / 2;
    final List<Rect> textRects = [];

    for (var slice in slices) {
      final sweepAngle = (slice.value / total) * 2 * pi;
      final midAngle = startAngle + sweepAngle / 2;
      startAngle += sweepAngle;

      if (slice.value / total < 0.02) continue;

      final isRightSide = cos(midAngle) >= 0;

      final startX = center.dx + outerRadius * cos(midAngle);
      final startY = center.dy + outerRadius * sin(midAngle);

      final extendDist = 15.0;
      final bendX = center.dx + (outerRadius + extendDist) * cos(midAngle);
      final bendY = center.dy + (outerRadius + extendDist) * sin(midAngle);

      final horizontalDist = 10.0;
      final endX = bendX + (isRightSide ? horizontalDist : -horizontalDist);

      final textPainter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${slice.label}\n',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
            TextSpan(
              text: '${(slice.value / total * 100).toStringAsFixed(1)}%',
              style: TextStyle(color: theme.disabledColor, fontSize: 10),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
        textAlign: isRightSide ? TextAlign.left : TextAlign.right,
      );

      textPainter.layout();

      double textX = isRightSide ? endX + 4 : endX - textPainter.width - 4;
      double textY = bendY - textPainter.height / 2;

      Rect rect = Rect.fromLTWH(
        textX,
        textY,
        textPainter.width,
        textPainter.height,
      );
      for (var existing in textRects) {
        if (rect.overlaps(existing)) {
          if (rect.center.dy > existing.center.dy) {
            textY = existing.bottom + 2;
          } else {
            textY = existing.top - rect.height - 2;
          }
          rect = Rect.fromLTWH(
            textX,
            textY,
            textPainter.width,
            textPainter.height,
          );
        }
      }
      textRects.add(rect);

      final linePaint = Paint()
        ..color = slice.color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final path = Path()
        ..moveTo(startX, startY)
        ..lineTo(bendX, bendY)
        ..lineTo(endX, bendY);

      canvas.drawPath(path, linePaint);
      textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.total != total ||
        oldDelegate.innerSlices != innerSlices ||
        oldDelegate.outerSlices != outerSlices;
  }
}
