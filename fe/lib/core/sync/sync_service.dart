import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../storage/local_storage_service.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError('localStorageServiceProvider must be overridden in ProviderScope');
});

class SyncService {
  final ApiClient _api = ApiClient();
  final LocalStorageService _storage;

  SyncService(this._storage);

  Future<bool> initialMerge() async {
    final payload = _storage.exportForSync();
    
    final response = await _api.post(
      '/sync/initial',
      body: payload,
    );

    if (response.success) {
      await _storage.setCloudSynced(true);
      return true;
    }
    return false;
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return SyncService(storage);
});
