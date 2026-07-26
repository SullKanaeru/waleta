import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/sync/sync_service.dart';
import '../../activity/providers/transactions_provider.dart';
import '../../envelopes/providers/envelope_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class Account {
  final String id;
  final String name;
  final double balance;

  Account({required this.id, required this.name, required this.balance});

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      balance: (json['balance'] ?? 0).toDouble(),
    );
  }
}

class AccountsNotifier extends AsyncNotifier<List<Account>> {
  final _api = ApiClient();

  @override
  Future<List<Account>> build() async {
    return _fetchAccounts();
  }

  bool _isCashName(String name) {
    final n = name.toLowerCase();
    return n.contains('tunai') ||
        n.contains('cash') ||
        n.contains('dompet') ||
        n.contains('saku') ||
        n.contains('gopay') ||
        n.contains('ovo') ||
        n.contains('dana') ||
        n.contains('shopee') ||
        n.contains('linkaja') ||
        n.contains('flazz') ||
        n.contains('emoney') ||
        n.contains('e-money');
  }

  Future<List<Account>> _fetchAccounts() async {
    final isLoggedIn = ref.watch(authProvider).isLoggedIn;
    if (!isLoggedIn) {
      final storage = ref.read(localStorageServiceProvider);
      final raw = storage.getAccounts();
      if (!raw.any((e) => _isCashName((e['name'] ?? '').toString()))) {
        raw.insert(0, {
          'id': 'a_default_cash',
          'name': 'Tunai',
          'balance': 0.0,
        });
        await storage.saveAccounts(raw);
      }

      // Reconcile: If account balance was reduced by previous envelope allocation bug, restore it
      final envs = storage.getEnvelopes();
      final pockets = storage.getPockets();
      double totalAllocatedInEnvelopes = 0;
      for (var e in envs) {
        totalAllocatedInEnvelopes += (e['total_allocated'] ?? 0).toDouble();
      }
      for (var p in pockets) {
        totalAllocatedInEnvelopes += (p['balance'] ?? 0).toDouble();
      }

      if (totalAllocatedInEnvelopes > 0) {
        double sumAccountBalances = 0;
        for (var a in raw) {
          sumAccountBalances += (a['balance'] ?? 0).toDouble();
        }
        if (sumAccountBalances == 0) {
          bool updated = false;
          for (var a in raw) {
            if (!_isCashName((a['name'] ?? '').toString())) {
              a['balance'] = totalAllocatedInEnvelopes;
              updated = true;
              break;
            }
          }
          if (updated) {
            await storage.saveAccounts(raw);
          }
        }
      }

      return raw
          .map(
            (e) => Account(
              id: e['id'] ?? '',
              name: e['name'] ?? '',
              balance: (e['balance'] ?? 0).toDouble(),
            ),
          )
          .toList();
    }

    final response = await _api.get(ApiEndpoints.accounts);
    if (response.success && response.data != null) {
      final list = response.data as List;
      final accounts = list
          .map((e) => Account.fromJson(e as Map<String, dynamic>))
          .toList();
      final storage = ref.read(localStorageServiceProvider);
      await storage.saveAccounts(list.map((e) => e as Map<String, dynamic>).toList());
      return accounts;
    }
    return [];
  }

  Future<bool> createAccount(String name, double balance) async {
    if (!ref.read(authProvider).isLoggedIn) {
      final storage = ref.read(localStorageServiceProvider);
      final accounts = storage.getAccounts();
      accounts.add({
        'id': 'a_${DateTime.now().millisecondsSinceEpoch}',
        'name': name,
        'balance': balance,
      });
      await storage.saveAccounts(accounts);
      ref.invalidateSelf();
      return true;
    }

    final response = await _api.post(
      ApiEndpoints.accounts,
      body: {'name': name, 'balance': balance},
    );

    if (response.success) {
      ref.invalidateSelf(); // Refresh list
      return true;
    }
    return false;
  }

  Future<bool> reconcileBalance(
    String accountId,
    double newBalance,
    double difference,
    String? pocketId,
  ) async {
    if (!ref.read(authProvider).isLoggedIn) {
      final storage = ref.read(localStorageServiceProvider);
      final accounts = storage.getAccounts();
      for (var a in accounts) {
        if (a['id'] == accountId) {
          a['balance'] = newBalance;
        }
      }
      await storage.saveAccounts(accounts);

      if (difference != 0) {
        final txs = storage.getTransactions();
        txs.add({
          'id': 't_${DateTime.now().millisecondsSinceEpoch}',
          'amount': difference.abs(),
          'account_id': accountId,
          'merchant_name': 'Koreksi Saldo Sistem',
          'notes': 'Koreksi Saldo',
          'pocket_id': pocketId,
          'master_id': pocketId,
          'date': DateTime.now().toIso8601String(),
          'type': difference > 0 ? 'INCOME' : 'EXPENSE',
        });
        await storage.saveTransactions(txs);
      }

      // Auto-Sweep: Find any negative pockets and reset them
      final pockets = storage.getPockets();
      final envelopes = storage.getEnvelopes();
      bool envelopesChanged = false;
      bool pocketsChanged = false;

      for (var p in pockets) {
        final bal = (p['balance'] ?? 0).toDouble();
        if (bal < 0) {
          final absDiff = bal.abs();
          p['balance'] = 0.0;
          pocketsChanged = true;

          // Find master envelope and increase allocated amount
          final masterId = p['master_id'];
          for (var env in envelopes) {
            if (env['id'] == masterId) {
              env['allocatedAmount'] =
                  (env['allocatedAmount'] ?? 0).toDouble() + absDiff;
              envelopesChanged = true;
              break;
            }
          }
        }
      }

      if (pocketsChanged) await storage.savePockets(pockets);
      if (envelopesChanged) await storage.saveEnvelopes(envelopes);

      ref.invalidateSelf();
      ref.invalidate(transactionsProvider);
      ref.invalidate(envelopesProvider);
      ref.invalidate(dashboardProvider);
      return true;
    }

    final response = await _api.post(
      ApiEndpoints.reconcileAccount(accountId),
      body: {
        'new_balance': newBalance,
        'difference': difference,
        'pocket_id': pocketId,
      },
    );

    if (response.success) {
      ref.invalidateSelf();
      ref.invalidate(transactionsProvider);
      ref.invalidate(envelopesProvider);
      ref.invalidate(dashboardProvider);
      return true;
    }
    return false;
  }

  void refresh() {
    ref.invalidateSelf();
  }

  Future<bool> freshStart() async {
    final storage = ref.read(localStorageServiceProvider);

    // Reset Accounts
    final accounts = storage.getAccounts();
    for (var a in accounts) {
      a['balance'] = 0.0;
    }
    await storage.saveAccounts(accounts);

    // Reset Envelopes
    final envs = storage.getEnvelopes();
    for (var e in envs) {
      e['total_allocated'] = 0.0;
    }
    await storage.saveEnvelopes(envs);

    // Reset Pockets
    final pockets = storage.getPockets();
    for (var p in pockets) {
      p['balance'] = 0.0;
    }
    await storage.savePockets(pockets);

    if (!ref.read(authProvider).isLoggedIn) {
      ref.invalidateSelf();
      ref.invalidate(envelopesProvider);
      ref.invalidate(dashboardProvider);
      return true;
    }

    final response = await _api.post(ApiEndpoints.freshStart);
    if (response.success) {
      ref.invalidateSelf();
      ref.invalidate(envelopesProvider);
      ref.invalidate(dashboardProvider);
      return true;
    }
    return false;
  }
}

final accountsProvider = AsyncNotifierProvider<AccountsNotifier, List<Account>>(
  AccountsNotifier.new,
);
