import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';

class RolloverDialog extends StatelessWidget {
  final double savedAmount;
  final VoidCallback onTransfer;
  final VoidCallback onSkip;

  const RolloverDialog({
    super.key,
    required this.savedAmount,
    required this.onTransfer,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Calculate future value: 6% p.a., 5 years, monthly contribution = savedAmount
    const double ratePerYear = 0.06;
    const int years = 5;
    const int n = 12; // monthly
    final double ratePerPeriod = ratePerYear / n;
    final int totalPeriods = years * n;
    
    // Future Value of an Annuity formula
    final double futureValue = savedAmount * ((pow(1 + ratePerPeriod, totalPeriods) - 1) / ratePerPeriod);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.trendingUp, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Bulan Baru, Rekor Baru!',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Bulan lalu kamu berhasil berhemat sebesar:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              formatter.format(savedAmount),
              style: theme.textTheme.displaySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.lightbulb, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Tahukah Kamu?',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jika uang sisa ini rutin diinvestasikan ke instrumen reksa dana 6% per tahun, dalam 5 tahun nilainya akan menjadi:',
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatter.format(futureValue),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Mau pindahkan sisa uang ini ke Tabungan sekarang?',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSkip,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Nanti Saja'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onTransfer,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Pindahkan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void showRolloverDialog(BuildContext context, double savedAmount, VoidCallback onTransfer) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => RolloverDialog(
      savedAmount: savedAmount,
      onTransfer: () {
        Navigator.pop(ctx);
        onTransfer();
      },
      onSkip: () => Navigator.pop(ctx),
    ),
  );
}
