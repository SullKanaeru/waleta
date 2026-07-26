import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/sync/sync_service.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../envelopes/providers/envelope_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class Transaction {
  final String id;
  final double amount;
  final String accountId;
  final String? pocketId;
  final String merchantName;
  final String notes;
  final DateTime date;
  final Map<String, dynamic>? ocrItems;
  final String type;

  Transaction({
    required this.id,
    required this.amount,
    required this.accountId,
    this.pocketId,
    required this.merchantName,
    required this.notes,
    required this.date,
    this.ocrItems,
    this.type = 'INCOME',
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final amt = (json['amount'] ?? 0).toDouble();
    final type = json['type'] ?? 'INCOME';
    return Transaction(
      id: json['id'] ?? '',
      amount: type == 'EXPENSE' ? -amt : amt,
      accountId: json['account_id'] ?? '',
      pocketId: json['pocket_id'],
      merchantName: json['merchant_name'] ?? '',
      notes: json['notes'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      ocrItems: json['ocr_items'],
      type: type,
    );
  }
}

class TransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  final _api = ApiClient();

  @override
  Future<List<Transaction>> build() async {
    return _fetchTransactions();
  }

  Future<List<Transaction>> _fetchTransactions() async {
    final isLoggedIn = ref.watch(authProvider).isLoggedIn;
    if (!isLoggedIn) {
      final storage = ref.read(localStorageServiceProvider);
      final raw = storage.getTransactions();
      return raw.map((e) {
        final amt = (e['amount'] ?? 0).toDouble();
        final type = e['type'] ?? (e['pocket_id'] != null ? 'EXPENSE' : 'INCOME');
        return Transaction(
          id: e['id'] ?? '',
          amount: type == 'EXPENSE' ? -amt : amt,
          accountId: e['account_id'] ?? '',
          pocketId: e['pocket_id'],
          merchantName: e['merchant_name'] ?? '',
          notes: e['notes'] ?? '',
          date: DateTime.tryParse(e['date'] ?? '') ?? DateTime.now(),
          ocrItems: e['ocr_items'],
          type: type,
        );
      }).toList();
    }

    final response = await _api.get(ApiEndpoints.transactions);
    if (response.success && response.data != null) {
      final list = response.data as List;
      return list.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<bool> addIncome(double amount, String accountId, String merchantName, String notes) async {
    if (!ref.read(authProvider).isLoggedIn) {
      final storage = ref.read(localStorageServiceProvider);
      final txs = storage.getTransactions();
      txs.add({
        'id': 't_${DateTime.now().millisecondsSinceEpoch}',
        'amount': amount,
        'type': 'INCOME',
        'account_id': accountId,
        'merchant_name': merchantName,
        'notes': notes,
        'date': DateTime.now().toIso8601String(),
      });
      await storage.saveTransactions(txs);
      
      final accounts = storage.getAccounts();
      for (var a in accounts) {
        if (a['id'] == accountId) {
          a['balance'] = (a['balance'] ?? 0) + amount;
        }
      }
      await storage.saveAccounts(accounts);

      ref.invalidateSelf();
      ref.invalidate(accountsProvider);
      ref.invalidate(envelopesProvider);
      ref.invalidate(dashboardProvider);
      return true;
    }

    final response = await _api.post(ApiEndpoints.transactionIncome, body: {
      'amount': amount,
      'account_id': accountId,
      'merchant_name': merchantName,
      'notes': notes,
    });

    if (response.success) {
      ref.invalidateSelf();
      ref.invalidate(accountsProvider);
      ref.invalidate(envelopesProvider);
      ref.invalidate(dashboardProvider);
      return true;
    }
    return false;
  }
  
  Future<bool> addExpense(double amount, String accountId, String? pocketId, String merchantName, String notes, Map<String, dynamic>? ocrItems) async {
    if (!ref.read(authProvider).isLoggedIn) {
      final storage = ref.read(localStorageServiceProvider);
      final txs = storage.getTransactions();
      txs.add({
        'id': 't_${DateTime.now().millisecondsSinceEpoch}',
        'amount': amount,
        'type': 'EXPENSE',
        'account_id': accountId,
        'pocket_id': pocketId,
        'merchant_name': merchantName,
        'notes': notes,
        'date': DateTime.now().toIso8601String(),
        'ocr_items': ocrItems,
      });
      await storage.saveTransactions(txs);
      
      final accounts = storage.getAccounts();
      for (var a in accounts) {
        if (a['id'] == accountId) {
          a['balance'] = (a['balance'] ?? 0) - amount;
        }
      }
      await storage.saveAccounts(accounts);

      if (pocketId != null) {
        final pockets = storage.getPockets();
        String? masterId;
        for (var p in pockets) {
          if (p['id'] == pocketId) {
            p['balance'] = (p['balance'] ?? 0) - amount;
            masterId = p['master_id'];
          }
        }
        
        if (masterId != null) {
          await storage.savePockets(pockets);
          final envs = storage.getEnvelopes();
          for (var e in envs) {
            if (e['id'] == masterId) {
              e['total_allocated'] = (e['total_allocated'] ?? 0) - amount;
            }
          }
          await storage.saveEnvelopes(envs);
        } else {
          // pocketId is actually an envelopeId
          final envs = storage.getEnvelopes();
          bool updatedEnv = false;
          for (var e in envs) {
            if (e['id'] == pocketId) {
              e['total_allocated'] = (e['total_allocated'] ?? 0) - amount;
              updatedEnv = true;
            }
          }
          if (updatedEnv) {
            await storage.saveEnvelopes(envs);
          }
        }
      }

      ref.invalidateSelf();
      ref.invalidate(accountsProvider);
      ref.invalidate(envelopesProvider);
      ref.invalidate(dashboardProvider);
      return true;
    }

    final response = await _api.post(ApiEndpoints.transactionExpense, body: {
      'amount': amount,
      'account_id': accountId,
      'pocket_id': pocketId,
      'merchant_name': merchantName,
      'notes': notes,
      if (ocrItems != null) 'ocr_items': ocrItems,
    });

    if (response.success) {
      ref.invalidateSelf();
      ref.invalidate(accountsProvider);
      ref.invalidate(envelopesProvider);
      ref.invalidate(dashboardProvider);
      return true;
    }
    return false;
  }

  Future<bool> deleteTransactions(List<String> ids) async {
    if (!ref.read(authProvider).isLoggedIn) {
      final storage = ref.read(localStorageServiceProvider);
      final txs = storage.getTransactions();
      
      // Revert balances for each deleted tx
      for (var id in ids) {
        final txIndex = txs.indexWhere((t) => t['id'] == id);
        if (txIndex >= 0) {
          final tx = txs[txIndex];
          final type = tx['type'] ?? (tx['pocket_id'] != null ? 'EXPENSE' : 'INCOME');
          final amount = (tx['amount'] ?? 0).toDouble();
          
          if (tx['account_id'] != null) {
            final accounts = storage.getAccounts();
            for (var a in accounts) {
              if (a['id'] == tx['account_id']) {
                if (type == 'INCOME') {
                  a['balance'] = (a['balance'] ?? 0) - amount;
                } else if (type == 'EXPENSE') {
                  a['balance'] = (a['balance'] ?? 0) + amount;
                }
              }
            }
            await storage.saveAccounts(accounts);
          }
          
          if (tx['pocket_id'] != null && type == 'EXPENSE') {
            final pockets = storage.getPockets();
            String? masterId;
            for (var p in pockets) {
              if (p['id'] == tx['pocket_id']) {
                p['balance'] = (p['balance'] ?? 0) + amount;
                masterId = p['master_id'];
              }
            }
            if (masterId != null) {
              await storage.savePockets(pockets);
              final envs = storage.getEnvelopes();
              for (var e in envs) {
                if (e['id'] == masterId) {
                  e['total_allocated'] = (e['total_allocated'] ?? 0) + amount;
                }
              }
              await storage.saveEnvelopes(envs);
            }
          }
        }
      }
      
      txs.removeWhere((t) => ids.contains(t['id']));
      await storage.saveTransactions(txs);
      
      ref.invalidateSelf();
      ref.invalidate(accountsProvider);
      ref.invalidate(envelopesProvider);
      ref.invalidate(dashboardProvider);
      return true;
    }

    final response = await _api.delete(ApiEndpoints.transactions, body: {
      'ids': ids,
    });

    if (response.success) {
      ref.invalidateSelf();
      ref.invalidate(accountsProvider);
      ref.invalidate(envelopesProvider);
      ref.invalidate(dashboardProvider);
      return true;
    }
    return false;
  }

  Future<bool> updateTransaction(String id, String merchantName, String notes) async {
    if (!ref.read(authProvider).isLoggedIn) {
      final storage = ref.read(localStorageServiceProvider);
      final txs = storage.getTransactions();
      
      final index = txs.indexWhere((t) => t['id'] == id);
      if (index >= 0) {
        txs[index]['merchant_name'] = merchantName;
        txs[index]['notes'] = notes;
        await storage.saveTransactions(txs);
        
        ref.invalidateSelf();
        return true;
      }
      return false;
    }

    final response = await _api.put('${ApiEndpoints.transactions}/$id', body: {
      'merchant_name': merchantName,
      'notes': notes,
    });

    if (response.success) {
      ref.invalidateSelf();
      return true;
    }
    return false;
  }

  void refresh() {
    ref.invalidateSelf();
  }
}

final transactionsProvider = AsyncNotifierProvider<TransactionsNotifier, List<Transaction>>(
  TransactionsNotifier.new,
);

class InboxNotifier extends AsyncNotifier<List<Transaction>> {
  final _api = ApiClient();

  @override
  Future<List<Transaction>> build() async {
    return _fetchInbox();
  }

  Future<List<Transaction>> _fetchInbox() async {
    final isLoggedIn = ref.watch(authProvider).isLoggedIn;
    if (!isLoggedIn) {
      final storage = ref.read(localStorageServiceProvider);
      final raw = storage.getInbox();
      return raw.map((e) => Transaction(
        id: e['id'] ?? '',
        amount: (e['amount'] ?? 0).toDouble(),
        type: e['type'] ?? 'EXPENSE',
        accountId: e['account_id'] ?? '',
        pocketId: e['pocket_id'],
        merchantName: e['merchant_name'] ?? '',
        notes: e['notes'] ?? '',
        date: DateTime.tryParse(e['date'] ?? '') ?? DateTime.now(),
        ocrItems: e['ocr_items'],
      )).toList();
    }

    final response = await _api.get(ApiEndpoints.transactionInbox);
    if (response.success && response.data != null) {
      final list = response.data as List;
      return list.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<bool> assignInbox(String transactionId, String pocketId, bool autoCategorize) async {
    if (!ref.read(authProvider).isLoggedIn) {
      final storage = ref.read(localStorageServiceProvider);
      final inbox = storage.getInbox();
      final txs = storage.getTransactions();
      
      final index = inbox.indexWhere((t) => t['id'] == transactionId);
      if (index == -1) return false;
      
      final t = inbox[index];
      final amount = (t['amount'] ?? 0).toDouble().abs();
      final accountId = t['account_id'] ?? '';
      
      // Move to regular transactions
      t['pocket_id'] = pocketId;
      txs.add(t);
      await storage.saveTransactions(txs);
      
      // Remove from inbox
      inbox.removeAt(index);
      await storage.saveInbox(inbox);
      
      // Subtract from account balance (real expense decreases bank account!)
      final accounts = storage.getAccounts();
      for (var a in accounts) {
        if (a['id'] == accountId) {
          a['balance'] = (a['balance'] ?? 0) - amount;
        }
      }
      await storage.saveAccounts(accounts);
      
      // Subtract from pocket balance
      final pockets = storage.getPockets();
      for (var p in pockets) {
        if (p['id'] == pocketId) {
          p['balance'] = (p['balance'] ?? 0) - amount;
        }
      }
      await storage.savePockets(pockets);
      
      ref.invalidateSelf();
      ref.invalidate(transactionsProvider);
      ref.invalidate(accountsProvider);
      ref.invalidate(envelopesProvider);
      ref.invalidate(dashboardProvider);
      return true;
    }

    final response = await _api.post(ApiEndpoints.assignInbox(transactionId), body: {
      'pocket_id': pocketId,
      'auto_categorize': autoCategorize,
    });

    if (response.success) {
      ref.invalidateSelf();
      ref.invalidate(transactionsProvider);
      ref.invalidate(accountsProvider);
      ref.invalidate(envelopesProvider);
      ref.invalidate(dashboardProvider);
      return true;
    }
    return false;
  }

  // Method to insert a transaction to the offline inbox (useful for test cases/OCR scanner flow if they want it in Inbox)
  Future<bool> addToInboxOffline(double amount, String accountId, String merchantName, String notes) async {
    final storage = ref.read(localStorageServiceProvider);
    final inbox = storage.getInbox();
    inbox.add({
      'id': 't_${DateTime.now().millisecondsSinceEpoch}',
      'amount': amount,
      'type': 'EXPENSE',
      'account_id': accountId,
      'merchant_name': merchantName,
      'notes': notes,
      'date': DateTime.now().toIso8601String(),
    });
    await storage.saveInbox(inbox);
    ref.invalidateSelf();
    return true;
  }
  
  void refresh() {
    ref.invalidateSelf();
  }
}

final inboxProvider = AsyncNotifierProvider<InboxNotifier, List<Transaction>>(
  InboxNotifier.new,
);
