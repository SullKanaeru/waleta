import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _biometricEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final userName =
        (authState.user?.name != null && authState.user!.name.isNotEmpty)
        ? authState.user!.name
        : 'Alex';
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'A';
    final userEmail = authState.user?.email ?? 'alex@example.com';

    return Scaffold(
      appBar: AppBar(title: const Text('Profil & Jurnal'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildUserInfo(theme, userName, userEmail, initial),
          const SizedBox(height: 32),
          Text('Buyer\'s Remorse Radar', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Evaluasi transaksi besar bulan ini untuk mengenali pola belanja impulsif Anda.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _buildRemorseRadar(theme),
          const SizedBox(height: 32),
          Text('Pengaturan Keamanan', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildSecuritySettings(theme),
        ],
      ),
    );
  }

  Widget _buildUserInfo(
    ThemeData theme,
    String name,
    String email,
    String initial,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.primary,
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: theme.textTheme.displayMedium?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(email, style: theme.textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }

  Widget _buildRemorseRadar(ThemeData theme) {
    return GlassCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          _RemorseItem(
            title: 'Sepatu Sneakers X',
            amount: 'Rp 1.500.000',
            date: '12 Jul',
            icon: LucideIcons.shoppingBag,
            status: RemorseStatus.regret,
          ),
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
          _RemorseItem(
            title: 'Buku Clean Code',
            amount: 'Rp 350.000',
            date: '08 Jul',
            icon: LucideIcons.bookOpen,
            status: RemorseStatus.satisfied,
          ),
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
          _RemorseItem(
            title: 'Langganan Gym (Tahunan)',
            amount: 'Rp 3.600.000',
            date: '01 Jul',
            icon: LucideIcons.activity,
            status: RemorseStatus.neutral,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSecuritySettings(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: _biometricEnabled,
            onChanged: (val) => setState(() => _biometricEnabled = val),
            title: const Text('Biometric Lock (FaceID/Fingerprint)'),
            subtitle: const Text('Wajibkan verifikasi saat membuka aplikasi'),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.fingerprint,
                color: AppColors.primary,
              ),
            ),
          ),
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.05)),
          ListTile(
            title: const Text('Shake-to-Blur Sensitivity'),
            subtitle: const Text('Medium'),
            trailing: const Icon(LucideIcons.chevronRight),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentAmber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.smartphone,
                color: AppColors.accentAmber,
              ),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

enum RemorseStatus { satisfied, neutral, regret }

class _RemorseItem extends StatelessWidget {
  final String title;
  final String amount;
  final String date;
  final IconData icon;
  final RemorseStatus status;

  const _RemorseItem({
    required this.title,
    required this.amount,
    required this.date,
    required this.icon,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case RemorseStatus.satisfied:
        statusColor = AppColors.accentAmber;
        statusIcon = LucideIcons.smile;
        statusText = 'Puas';
        break;
      case RemorseStatus.neutral:
        statusColor = AppColors.warning;
        statusIcon = LucideIcons.meh;
        statusText = 'Biasa Saja';
        break;
      case RemorseStatus.regret:
        statusColor = AppColors.error;
        statusIcon = LucideIcons.frown;
        statusText = 'Menyesal';
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.iconTheme.color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text('$date • $amount', style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: statusColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
