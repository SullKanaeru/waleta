import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildUserInfo(theme),
          const SizedBox(height: 32),
          Text(
            'Pengaturan Keamanan & Privasi',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildSecuritySettings(theme),
          const SizedBox(height: 32),
          Text('Pengaturan Data', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildDataSettings(theme),
        ],
      ),
    );
  }

  Widget _buildUserInfo(ThemeData theme) {
    final authState = ref.watch(authProvider);
    final isLoggedIn = authState.isLoggedIn;
    final userName = authState.user?.name ?? 'Pengguna Tamu';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'P';
    final memberSince = isLoggedIn ? 'Member Waleta' : 'Mode Tamu (Offline)';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: isLoggedIn
              ? AppColors.primary
              : Colors.grey.shade400,
          child: Text(
            userInitial,
            style: const TextStyle(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: theme.textTheme.displayMedium?.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 4),
              Text(memberSince, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              if (!isLoggedIn)
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => context.push('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Masuk'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => context.push('/register'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Daftar'),
                    ),
                  ],
                )
              else
                OutlinedButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    context.go('/login');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Keluar'),
                ),
            ],
          ),
        ),
      ],
    );
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

  Widget _buildDataSettings(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          ListTile(
            title: const Text(
              'Mulai Lembaran Baru',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'Nolkan semua saldo saat ini tanpa menghapus riwayat transaksi masa lalu.',
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.refreshCcw, color: AppColors.error),
            ),
            onTap: _showFreshStartConfirm,
          ),
        ],
      ),
    );
  }

  void _showFreshStartConfirm() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Mulai Lembaran Baru?'),
          content: const Text(
            'Semua saldo Rekening, Dompet, dan Saku Anda saat ini akan diatur menjadi Rp 0.\n\nRiwayat dan statistik transaksi Anda di bulan-bulan sebelumnya tetap utuh. Anda yakin ingin melanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await ref
                    .read(accountsProvider.notifier)
                    .freshStart();
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Berhasil memulai lembaran baru! Silakan Sesuaikan Saldo Anda kembali.',
                      ),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, Lanjutkan'),
            ),
          ],
        );
      },
    );
  }
}
