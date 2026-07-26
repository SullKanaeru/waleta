import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isLoggedIn = authState.isLoggedIn;

    return Scaffold(
      appBar: AppBar(title: const Text('Akun & Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      user != null && user.name.isNotEmpty
                          ? user.name.substring(0, 1).toUpperCase()
                          : 'P',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Pengguna Offline',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? 'Penyimpanan Lokal',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Status
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isLoggedIn
                  ? AppColors.primary.withValues(alpha: 0.06)
                  : AppColors.warning.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isLoggedIn
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.warning.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isLoggedIn ? LucideIcons.cloud : LucideIcons.hardDrive,
                  color: isLoggedIn ? AppColors.primary : AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('Preferensi', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),

          _buildSettingsTile(
            context,
            icon: LucideIcons.palette,
            title: 'Tampilan & Tema',
            subtitle: 'Mode gelap atau terang',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: LucideIcons.shieldCheck,
            title: 'Keamanan & PIN',
            subtitle: 'Kunci dengan sidik jari atau PIN',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: LucideIcons.download,
            title: 'Ekspor Data',
            subtitle: 'Unduh laporan CSV atau PDF',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: LucideIcons.info,
            title: 'Tentang Waleta',
            subtitle: 'Versi 1.0.0',
            onTap: () {},
          ),

          const SizedBox(height: 24),
          if (isLoggedIn)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                },
                icon: const Icon(LucideIcons.logOut, size: 18),
                label: const Text('Keluar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        title: Text(title, style: theme.textTheme.titleSmall),
        subtitle: Text(subtitle, style: theme.textTheme.labelSmall),
        trailing: Icon(
          LucideIcons.chevronRight,
          size: 16,
          color: theme.disabledColor,
        ),
        onTap: onTap,
      ),
    );
  }
}
