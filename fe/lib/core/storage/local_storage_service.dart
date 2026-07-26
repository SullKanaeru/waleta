import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LocalStorageService {
  static const String _keyDeviceId = 'device_id';
  static const String _keyIsSynced = 'is_cloud_synced';
  static const String _keyAccounts = 'local_accounts';
  static const String _keyEnvelopes = 'local_envelopes';
  static const String _keyPockets = 'local_pockets';
  static const String _keyTransactions = 'local_transactions';
  static const String _keyInbox = 'local_inbox';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = LocalStorageService(prefs);
    await service._ensureDeviceId();
    return service;
  }

  Future<void> _ensureDeviceId() async {
    if (!_prefs.containsKey(_keyDeviceId)) {
      final newId = const Uuid().v4();
      await _prefs.setString(_keyDeviceId, newId);
    }
    if (!_prefs.containsKey(_keyIsSynced)) {
      await _prefs.setBool(_keyIsSynced, false);
    }
  }

  String getDeviceId() {
    return _prefs.getString(_keyDeviceId) ?? const Uuid().v4();
  }

  bool isCloudSynced() {
    return _prefs.getBool(_keyIsSynced) ?? false;
  }

  Future<void> setCloudSynced(bool value) async {
    await _prefs.setBool(_keyIsSynced, value);
  }

  // --- ACCOUNTS ---
  List<Map<String, dynamic>> getAccounts() {
    final str = _prefs.getString(_keyAccounts);
    if (str == null) return [];
    try {
      final List list = jsonDecode(str);
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAccounts(List<Map<String, dynamic>> accounts) async {
    await _prefs.setString(_keyAccounts, jsonEncode(accounts));
  }

  // --- MASTER ENVELOPES ---
  List<Map<String, dynamic>> getEnvelopes() {
    final str = _prefs.getString(_keyEnvelopes);
    if (str == null) {
      // Default offline master envelopes
      return [
        {'id': 'kebutuhan', 'name': 'Kebutuhan', 'total_allocated': 0.0},
        {'id': 'keinginan', 'name': 'Keinginan', 'total_allocated': 0.0},
        {'id': 'tabungan', 'name': 'Tabungan', 'total_allocated': 0.0},
      ];
    }
    try {
      final List list = jsonDecode(str);
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveEnvelopes(List<Map<String, dynamic>> envelopes) async {
    await _prefs.setString(_keyEnvelopes, jsonEncode(envelopes));
  }

  // --- POCKETS ---
  List<Map<String, dynamic>> getPockets() {
    final str = _prefs.getString(_keyPockets);
    if (str == null) return [];
    try {
      final List list = jsonDecode(str);
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePockets(List<Map<String, dynamic>> pockets) async {
    await _prefs.setString(_keyPockets, jsonEncode(pockets));
  }

  // --- TRANSACTIONS ---
  List<Map<String, dynamic>> getTransactions() {
    final str = _prefs.getString(_keyTransactions);
    if (str == null) return [];
    try {
      final List list = jsonDecode(str);
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTransactions(List<Map<String, dynamic>> transactions) async {
    await _prefs.setString(_keyTransactions, jsonEncode(transactions));
  }

  // --- INBOX ---
  List<Map<String, dynamic>> getInbox() {
    final str = _prefs.getString(_keyInbox);
    if (str == null) return [];
    try {
      final List list = jsonDecode(str);
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveInbox(List<Map<String, dynamic>> inbox) async {
    await _prefs.setString(_keyInbox, jsonEncode(inbox));
  }

  // --- SYNC EXPORT ---
  Map<String, dynamic> exportForSync() {
    return {
      'device_id': getDeviceId(),
      'sync_timestamp': DateTime.now().toUtc().toIso8601String(),
      'data': {
        'accounts': getAccounts(),
        'master_envelopes': getEnvelopes(),
        'pockets': getPockets(),
        'transactions': getTransactions(),
        'local_inbox': getInbox(),
        'sweeping_rules': [],
      }
    };
  }
}
