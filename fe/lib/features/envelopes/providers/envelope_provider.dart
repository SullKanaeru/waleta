import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/envelope.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/sync/sync_service.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class EnvelopesNotifier extends AsyncNotifier<List<Envelope>> {
  final _api = ApiClient();

  @override
  Future<List<Envelope>> build() async {
    return _fetchEnvelopes();
  }

  Future<List<Envelope>> _fetchEnvelopes() async {
    final isLoggedIn = ref.watch(authProvider).isLoggedIn;
    if (!isLoggedIn) {
      final storage = ref.read(localStorageServiceProvider);
      final rawEnvelopes = storage.getEnvelopes();
      final rawPockets = storage.getPockets();
      
      return rawEnvelopes.map((data) {
        final id = data['id'] ?? '';
        IconData envIcon = LucideIcons.folder;
        Color envColor = AppColors.primary;
        if (id == 'kebutuhan') {
          envIcon = LucideIcons.shoppingBag;
          envColor = AppColors.primary;
        } else if (id == 'keinginan') {
          envIcon = LucideIcons.coffee;
          envColor = AppColors.accent;
        } else if (id == 'tabungan') {
          envIcon = LucideIcons.wallet;
          envColor = Colors.teal;
        }

        final myPockets = rawPockets.where((p) => p['master_id'] == id).map((pData) {
          return Pocket(
            id: pData['id'] ?? '',
            name: pData['name'] ?? '',
            allocatedAmount: (pData['balance'] ?? 0).toDouble(),
            iconData: _getIconData(pData['icon']),
            color: _getColor(pData['color']),
            stsMode: _parseStsMode(pData['sts_mode']),
            stsPeriodDays: pData['sts_period_days'] ?? 0,
            stsStartDate: pData['sts_start_date'],
          );
        }).toList();

        return Envelope(
          id: id,
          name: data['name'] ?? '',
          allocatedAmount: (data['total_allocated'] ?? 0).toDouble(),
          iconData: envIcon,
          color: envColor,
          pockets: myPockets,
          sources: {},
        );
      }).toList();
    }

    final response = await _api.get(ApiEndpoints.envelopes);
    if (response.success && response.data != null) {
      final list = response.data as List;
      return list.map((e) {
        final data = e as Map<String, dynamic>;
        
        final id = data['id'] ?? '';
        
        // Dynamic icons & colors based on Envelope ID
        IconData envIcon = LucideIcons.folder;
        Color envColor = AppColors.primary;
        if (id == 'kebutuhan') {
          envIcon = LucideIcons.shoppingBag;
          envColor = AppColors.primary;
        } else if (id == 'keinginan') {
          envIcon = LucideIcons.coffee;
          envColor = AppColors.accent;
        } else if (id == 'tabungan') {
          envIcon = LucideIcons.wallet;
          envColor = Colors.teal;
        }

        // Parse nested pockets from backend
        final List<Pocket> parsedPockets = [];
        if (data['pockets'] != null) {
          final pocketsList = data['pockets'] as List;
          for (var p in pocketsList) {
            final pData = p as Map<String, dynamic>;
            parsedPockets.add(Pocket(
              id: pData['id'] ?? '',
              name: pData['name'] ?? '',
              allocatedAmount: (pData['balance'] ?? 0).toDouble(),
              iconData: _getIconData(pData['icon']),
              color: _getColor(pData['color']),
              stsMode: _parseStsMode(pData['sts_mode']),
              stsPeriodDays: pData['sts_period_days'] ?? 0,
              stsStartDate: pData['sts_start_date'],
            ));
          }
        }

        // Parse dynamic sources map from backend
        final Map<String, double> parsedSources = {};
        if (data['sources'] != null) {
          final sourcesMap = data['sources'] as Map<String, dynamic>;
          sourcesMap.forEach((key, value) {
            parsedSources[key] = (value ?? 0).toDouble();
          });
        }

        return Envelope(
          id: id,
          name: data['name'] ?? '',
          allocatedAmount: (data['total_allocated'] ?? 0).toDouble(),
          iconData: envIcon,
          color: envColor,
          pockets: parsedPockets,
          sources: parsedSources,
        );
      }).toList();
    }
    return [];
  }

  Future<bool> allocateFunds(String accountId, String masterId, String? pocketId, double amount) async {
    if (!ref.read(authProvider).isLoggedIn) {
      final storage = ref.read(localStorageServiceProvider);

      if (pocketId != null) {
        final pockets = storage.getPockets();
        for (var p in pockets) {
          if (p['id'] == pocketId) {
            p['balance'] = (p['balance'] ?? 0) + amount;
          }
        }
        await storage.savePockets(pockets);
      } else {
        final envs = storage.getEnvelopes();
        for (var e in envs) {
          if (e['id'] == masterId) {
            e['total_allocated'] = (e['total_allocated'] ?? 0) + amount;
          }
        }
        await storage.saveEnvelopes(envs);
      }
      ref.invalidateSelf();
      ref.invalidate(accountsProvider);
      ref.invalidate(dashboardProvider);
      return true;
    }

    final response = await _api.post(
      ApiEndpoints.allocateEnvelopes,
      body: {
        'account_id': accountId,
        'master_id': masterId,
        if (pocketId != null) 'pocket_id': pocketId,
        'amount': amount,
      },
    );

    if (response.success) {
      ref.invalidateSelf();
      ref.invalidate(accountsProvider);
      ref.invalidate(dashboardProvider);
      return true;
    }
    return false;
  }

  Future<bool> createPocket(
    String masterId,
    String name,
    double balance,
    String icon,
    String color, {
    StsMode stsMode = StsMode.daily,
    int? stsPeriodDays,
  }) async {
    if (!ref.read(authProvider).isLoggedIn) {
      final storage = ref.read(localStorageServiceProvider);
      final pockets = storage.getPockets();
      pockets.add({
        'id': 'p_${DateTime.now().millisecondsSinceEpoch}',
        'master_id': masterId,
        'name': name,
        'balance': balance,
        'icon': icon,
        'color': color,
        'sts_mode': _stsModeToString(stsMode),
        'sts_period_days': stsPeriodDays ?? 0,
        'sts_start_date': DateTime.now().toIso8601String().substring(0, 10),
      });
      await storage.savePockets(pockets);
      ref.invalidateSelf();
      return true;
    }

    final response = await _api.post(
      ApiEndpoints.pockets(masterId),
      body: {
        'name': name,
        'balance': balance,
        'icon': icon,
        'color': color,
        'sts_mode': _stsModeToString(stsMode),
        'sts_period_days': stsPeriodDays ?? 0,
        'sts_start_date': DateTime.now().toIso8601String().substring(0, 10),
      },
    );

    if (response.success) {
      ref.invalidateSelf();
      return true;
    }
    return false;
  }

  Future<bool> updatePocket(Pocket pocket) async {
    if (!ref.read(authProvider).isLoggedIn) {
      final storage = ref.read(localStorageServiceProvider);
      final pockets = storage.getPockets();
      for (var p in pockets) {
        if (p['id'] == pocket.id) {
          p['name'] = pocket.name;
          p['balance'] = pocket.allocatedAmount;
          p['icon'] = getIconName(pocket.iconData);
          p['color'] = getColorName(pocket.color);
          p['sts_mode'] = _stsModeToString(pocket.stsMode);
          p['sts_period_days'] = pocket.stsPeriodDays ?? 0;
        }
      }
      await storage.savePockets(pockets);
      ref.invalidateSelf();
      return true;
    }

    final response = await _api.put(
      '/envelopes/pockets/${pocket.id}',
      body: {
        'name': pocket.name,
        'balance': pocket.allocatedAmount,
        'icon': getIconName(pocket.iconData),
        'color': getColorName(pocket.color),
        'sts_mode': _stsModeToString(pocket.stsMode),
        'sts_period_days': pocket.stsPeriodDays ?? 0,
      },
    );

    if (response.success) {
      ref.invalidateSelf();
      return true;
    }
    return false;
  }

  Future<bool> deletePocket(String pocketId) async {
    if (!ref.read(authProvider).isLoggedIn) {
      final storage = ref.read(localStorageServiceProvider);
      final pockets = storage.getPockets();
      pockets.removeWhere((p) => p['id'] == pocketId);
      await storage.savePockets(pockets);
      ref.invalidateSelf();
      return true;
    }

    final response = await _api.delete('/envelopes/pockets/$pocketId');
    if (response.success) {
      ref.invalidateSelf();
      return true;
    }
    return false;
  }

  void updateEnvelope(Envelope env) {
    final currentList = state.value ?? [];
    final idx = currentList.indexWhere((e) => e.id == env.id);
    if (idx >= 0) {
      currentList[idx] = env;
    } else {
      currentList.add(env);
    }
    state = AsyncValue.data(List.from(currentList));
  }

  void refresh() {
    ref.invalidateSelf();
  }

  StsMode _parseStsMode(String? mode) {
    switch (mode) {
      case 'daily': return StsMode.daily;
      case 'custom_period': return StsMode.customPeriod;
      case 'lump_sum': return StsMode.lumpSum;
      case 'locked': return StsMode.locked;
      default: return StsMode.daily;
    }
  }

  String _stsModeToString(StsMode mode) {
    switch (mode) {
      case StsMode.daily: return 'daily';
      case StsMode.customPeriod: return 'custom_period';
      case StsMode.lumpSum: return 'lump_sum';
      case StsMode.locked: return 'locked';
      default: return 'daily';
    }
  }

  // Helpers to map string to IconData/Color
  IconData _getIconData(String? name) {
    switch (name) {
      case 'shoppingBag': return LucideIcons.shoppingBag;
      case 'car': return LucideIcons.car;
      case 'home': return LucideIcons.home;
      case 'coffee': return LucideIcons.coffee;
      case 'heart': return LucideIcons.heart;
      case 'plane': return LucideIcons.plane;
      case 'book': return LucideIcons.book;
      case 'monitorPlay': return LucideIcons.monitorPlay;
      case 'music': return LucideIcons.music;
      default: return LucideIcons.folder;
    }
  }

  Color _getColor(String? name) {
    switch (name) {
      case 'primary': return AppColors.primary;
      case 'accent': return AppColors.accent;
      case 'error': return AppColors.error;
      case 'warning': return AppColors.warning;
      case 'teal': return Colors.teal;
      case 'indigo': return Colors.indigo;
      case 'deepOrange': return Colors.deepOrange;
      case 'pink': return Colors.pink;
      case 'purple': return Colors.purple;
      default: return AppColors.primary;
    }
  }
}

// Helpers to map IconData/Color to string
String getIconName(IconData icon) {
  if (icon == LucideIcons.shoppingBag) return 'shoppingBag';
  if (icon == LucideIcons.car) return 'car';
  if (icon == LucideIcons.home) return 'home';
  if (icon == LucideIcons.coffee) return 'coffee';
  if (icon == LucideIcons.heart) return 'heart';
  if (icon == LucideIcons.plane) return 'plane';
  if (icon == LucideIcons.book) return 'book';
  if (icon == LucideIcons.monitorPlay) return 'monitorPlay';
  if (icon == LucideIcons.music) return 'music';
  return 'folder';
}

String getColorName(Color color) {
  if (color == AppColors.primary) return 'primary';
  if (color == AppColors.accent) return 'accent';
  if (color == AppColors.error) return 'error';
  if (color == AppColors.warning) return 'warning';
  if (color == Colors.teal) return 'teal';
  if (color == Colors.indigo) return 'indigo';
  if (color == Colors.deepOrange) return 'deepOrange';
  if (color == Colors.pink) return 'pink';
  if (color == Colors.purple) return 'purple';
  return 'primary';
}

final envelopesProvider = AsyncNotifierProvider<EnvelopesNotifier, List<Envelope>>(EnvelopesNotifier.new);
