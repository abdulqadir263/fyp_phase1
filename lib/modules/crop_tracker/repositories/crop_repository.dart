import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/crop_model.dart';
import '../services/crop_remote_service.dart';
import '../services/local_database.dart';

abstract class ICropRepository {
  Future<List<CropRecord>> getCrops(String userId);
  Future<void> addCrop(CropRecord crop);
  Future<void> updateCrop(CropRecord crop);
  Future<void> deleteCrop(String cropId, String userId);
  Future<void> syncToFirebase(String userId);
}

class CropRepository implements ICropRepository {
  final CropLocalService _local;
  final CropRemoteService _remote;

  CropRepository({
    CropLocalService? local,
    CropRemoteService? remote,
  })  : _local = local ?? CropLocalService.instance,
        _remote = remote ?? CropRemoteService.instance;

  Future<bool> get _isOnline async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // ── GET CROPS ──
  @override
  Future<List<CropRecord>> getCrops(String userId) async {
    try {
      // Pehle local se load karo
      final localCrops = await _local.getCrops(userId);

      // Online hai toh Firebase se sync karo
      if (await _isOnline) {
        await syncToFirebase(userId);
        final remoteCrops = await _remote.getCrops(userId);

        // Remote data local mein save karo
        for (final crop in remoteCrops) {
          await _local.upsertCrop(crop, isSynced: true);
        }
        return remoteCrops;
      }

      return localCrops;
    } catch (e) {
      // Offline fallback
      return await _local.getCrops(userId);
    }
  }

  // ── ADD ──
  @override
  Future<void> addCrop(CropRecord crop) async {
    // Hamesha local mein save karo
    await _local.upsertCrop(crop, isSynced: false);

    // Online hai toh Firebase mein bhi
    if (await _isOnline) {
      await _remote.upsertCrop(crop);
      await _local.markSynced(crop.id);
    }
  }

  // ── UPDATE ──
  @override
  Future<void> updateCrop(CropRecord crop) async {
    await _local.upsertCrop(crop, isSynced: false);

    if (await _isOnline) {
      await _remote.upsertCrop(crop);
      await _local.markSynced(crop.id);
    }
  }

  // ── DELETE ──
  @override
  Future<void> deleteCrop(String cropId, String userId) async {
    await _local.deleteCrop(cropId);

    if (await _isOnline) {
      await _remote.deleteCrop(cropId);
    }
  }

  // ── SYNC unsynced local data to Firebase ──
  @override
  Future<void> syncToFirebase(String userId) async {
    if (!await _isOnline) return;

    final unsynced = await _local.getUnsyncedCrops(userId);
    for (final crop in unsynced) {
      await _remote.upsertCrop(crop);
      await _local.markSynced(crop.id);
    }
  }
}