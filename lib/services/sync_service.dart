import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/sale_model.dart';
import '../utils/constants.dart';
import 'firestore_service.dart';

/// Unified offline sync engine.
/// Queues sales when offline, syncs them when connectivity returns.
/// Uses sale IDs to prevent duplicate uploads.
class SyncService {
  Box? _box;
  final FirestoreService _firestoreService = FirestoreService();
  final Uuid _uuid = const Uuid();
  bool _isSyncing = false;

  /// Initialize the Hive box. Call once on app startup.
  Future<void> initialize() async {
    _box = await Hive.openBox(kOfflineSalesBox);
  }

  Box get _salesBox {
    if (_box == null || !_box!.isOpen) {
      throw StateError('SyncService not initialized. Call initialize() first.');
    }
    return _box!;
  }

  /// Queue a sale for offline sync.
  /// Assigns a unique ID if not set, and marks as unsynced.
  Future<void> queueSale(SaleModel sale) async {
    final saleId = sale.saleId.isNotEmpty ? sale.saleId : _uuid.v4();
    final saleWithId = SaleModel(
      saleId: saleId,
      staffId: sale.staffId,
      staffName: sale.staffName,
      items: sale.items,
      totalAmount: sale.totalAmount,
      paymentMethod: sale.paymentMethod,
      timestamp: sale.timestamp,
    );

    final entry = {
      'sale': saleWithId.toHiveMap(),
      'synced': false,
      'queued_at': DateTime.now().toIso8601String(),
    };

    // Use sale ID as key to prevent duplicates
    await _salesBox.put(saleId, entry);
    debugPrint('SyncService: Queued sale $saleId for offline sync');
  }

  /// Sync all pending (unsynced) sales to Firestore.
  /// Returns the number of successfully synced sales.
  Future<int> syncPendingSales() async {
    if (_isSyncing) return 0;
    _isSyncing = true;

    int syncedCount = 0;

    try {
      final keys = _salesBox.keys.toList();

      for (final key in keys) {
        final entry = Map<String, dynamic>.from(_salesBox.get(key) as Map);

        if (entry['synced'] == true) {
          // Already synced — remove from queue
          await _salesBox.delete(key);
          continue;
        }

        try {
          final sale = SaleModel.fromHiveMap(
              Map<dynamic, dynamic>.from(entry['sale'] as Map));
          await _firestoreService.createSale(sale);

          // Mark as synced and remove
          await _salesBox.delete(key);
          syncedCount++;
          debugPrint('SyncService: Synced sale ${sale.saleId}');
        } catch (e) {
          debugPrint('SyncService: Failed to sync sale $key: $e');
          // Leave in queue for next attempt
        }
      }
    } finally {
      _isSyncing = false;
    }

    return syncedCount;
  }

  /// Number of sales pending sync.
  int get pendingCount {
    try {
      int count = 0;
      for (final key in _salesBox.keys) {
        final entry = _salesBox.get(key);
        if (entry != null) {
          final map = Map<String, dynamic>.from(entry as Map);
          if (map['synced'] != true) count++;
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  /// Whether there are pending sales to sync.
  bool get hasPending => pendingCount > 0;

  /// Whether a sync is currently in progress.
  bool get isSyncing => _isSyncing;

  /// Clear all synced entries (maintenance).
  Future<void> clearSynced() async {
    final keys = _salesBox.keys.toList();
    for (final key in keys) {
      final entry = _salesBox.get(key);
      if (entry != null) {
        final map = Map<String, dynamic>.from(entry as Map);
        if (map['synced'] == true) {
          await _salesBox.delete(key);
        }
      }
    }
  }
}
