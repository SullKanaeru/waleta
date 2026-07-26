import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

class RolloverDialog extends StatelessWidget {
  final bool isSurplus;
  final double amount;
  final String sourceEnvelopeName;

  const RolloverDialog({
    super.key,
    required this.isSurplus,
    required this.amount,
    required this.sourceEnvelopeName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isSurplus ? AppColors.accent.withValues(alpha: 0.5) : AppColors.error.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSurplus ? AppColors.accent.withValues(alpha: 0.2) : AppColors.error.withValues(alpha: 0.2),
              blurRadius: 24,
              spreadRadius: 8,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSurplus ? AppColors.accent.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSurplus ? LucideIcons.partyPopper : LucideIcons.alertTriangle,
                size: 48,
                color: isSurplus ? AppColors.accent : AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              isSurplus ? 'Selebrasi Penghematan!' : 'Evaluasi Amplop',
              style: theme.textTheme.displayMedium?.copyWith(
                fontSize: 24,
                color: isSurplus ? AppColors.accent : AppColors.error,
              ),
            ),
            const SizedBox(height: 12),
            
            // Description
            Text(
              isSurplus
                  ? 'Hebat! Anda berhasil berhemat ${formatter.format(amount)} dari Amplop $sourceEnvelopeName bulan lalu!'
                  : 'Bulan lalu Amplop $sourceEnvelopeName tekor ${formatter.format(amount)}. Mari tutupi agar siklus bulan ini sehat.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 32),

            // Call to Actions
            if (isSurplus) ...[
              _buildCTA(
                context: context,
                title: 'Investasikan',
                subtitle: 'Pindahkan ke Tabungan Darurat',
                icon: LucideIcons.trendingUp,
                color: AppColors.accent,
                isPrimary: true,
              ),
              const SizedBox(height: 12),
              _buildCTA(
                context: context,
                title: 'Beri Hadiah Diri Sendiri',
                subtitle: 'Pindahkan ke Amplop Keinginan',
                icon: LucideIcons.coffee,
                color: AppColors.primary,
                isPrimary: false,
              ),
              const SizedBox(height: 12),
              _buildCTA(
                context: context,
                title: 'Bawa ke Bulan Depan',
                subtitle: 'Biarkan di Amplop $sourceEnvelopeName',
                icon: LucideIcons.calendarDays,
                color: Colors.grey,
                isPrimary: false,
              ),
            ] else ...[
              _buildCTA(
                context: context,
                title: 'Tarik dari Tabungan',
                subtitle: 'Mengurangi target tabungan darurat',
                icon: LucideIcons.piggyBank,
                color: AppColors.error,
                isPrimary: true,
              ),
              const SizedBox(height: 12),
              _buildCTA(
                context: context,
                title: 'Potong Jatah Keinginan',
                subtitle: 'Mengurangi anggaran hobi bulan ini',
                icon: LucideIcons.shoppingBag,
                color: AppColors.warning,
                isPrimary: false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCTA({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isPrimary,
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Keputusan diterapkan! Mutasi ${isSurplus ? "reward" : "bailout"} sedang diproses.'),
            backgroundColor: color,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPrimary ? color.withValues(alpha: 0.1) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? color : theme.dividerColor.withValues(alpha: 0.1),
            width: isPrimary ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isPrimary ? color : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
