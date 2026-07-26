import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/sync/sync_service.dart';

class DashboardSummary {
  final double safeToSpend;
  final double totalFunds;
  final double totalAllocated;
  final double unallocated;

  DashboardSummary({
    required this.safeToSpend,
    required this.totalFunds,
    required this.totalAllocated,
    required this.unallocated,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      safeToSpend: (json['safe_to_spend'] ?? 0).toDouble(),
      totalFunds: (json['total_funds'] ?? 0).toDouble(),
      totalAllocated: (json['total_allocated'] ?? 0).toDouble(),
      unallocated: (json['unallocated'] ?? 0).toDouble(),
    );
  }
}

class DashboardNotifier extends AsyncNotifier<DashboardSummary?> {
  final _api = ApiClient();

  @override
  Future<DashboardSummary?> build() async {
    return _fetchSummary();
  }

  Future<DashboardSummary?> _fetchSummary() async {
    final isLoggedIn = ref.watch(authProvider).isLoggedIn;
    if (!isLoggedIn) {
      final storage = ref.read(localStorageServiceProvider);
      final accounts = storage.getAccounts();
      final envs = storage.getEnvelopes();
      
      double totalEnvelopesAllocated = 0;
      for (var e in envs) {
        totalEnvelopesAllocated += (e['total_allocated'] ?? 0).toDouble();
      }
      double totalAccountFunds = 0;
      for (var a in accounts) {
        totalAccountFunds += (a['balance'] ?? 0).toDouble();
      }
      double totalNegativePockets = 0.0;
      final pockets = storage.getPockets();
      for (var p in pockets) {
        final bal = (p['balance'] ?? 0).toDouble();
        if (bal < 0) totalNegativePockets += bal.abs();
      }
      
      final totalFunds = totalAccountFunds;
      final unallocated = totalAccountFunds - totalEnvelopesAllocated - totalNegativePockets;
      final safeToSpend = unallocated.clamp(0.0, double.infinity);

      return DashboardSummary(
        safeToSpend: safeToSpend,
        totalFunds: totalFunds,
        totalAllocated: totalEnvelopesAllocated,
        unallocated: unallocated,
      );
    }

    final response = await _api.get(ApiEndpoints.dashboardSummary);
    if (response.success && response.data != null) {
      return DashboardSummary.fromJson(response.data);
    }
    return null;
  }

  void refresh() {
    ref.invalidateSelf();
  }
}

final dashboardProvider = AsyncNotifierProvider<DashboardNotifier, DashboardSummary?>(
  DashboardNotifier.new,
);

// Helper providers for backward compatibility in UI
final totalFundsProvider = Provider<double>((ref) {
  final summary = ref.watch(dashboardProvider).value;
  return summary?.totalFunds ?? 0.0;
});

final safeToSpendProvider = Provider<double>((ref) {
  final summary = ref.watch(dashboardProvider).value;
  return summary?.unallocated ?? 0.0; // Changed to unallocated so AllocateFundsSheet shows true value
});
