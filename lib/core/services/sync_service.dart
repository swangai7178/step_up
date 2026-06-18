import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:step_up_clone/core/constants/app_constants.dart';
import 'package:step_up_clone/core/database/local_database.dart';
import 'package:step_up_clone/features/dashboard/data/models/daily_metric_model.dart';

class SyncService {
  final LocalDatabase _db;

  SyncService({LocalDatabase? db}) : _db = db ?? LocalDatabase();

  /// Scans the database for un-synchronized metric blocks from previous days and pushes them.
  Future<bool> syncPendingDays() async {
    if (!_db.isInitialized) {
      log('Sync aborted: Local database is not initialized.');
      return false;
    }

    final isar = _db.instance;
    
    // 1. Fetch records where sync status is 'pending' or 'failed'
    final pendingRecords = await isar.dailyMetricModels
        .filter()
        .syncStatusEqualTo('pending')
        .or()
        .syncStatusEqualTo('failed')
        .findAll();

    if (pendingRecords.isEmpty) {
      log('Sync Engine: Complete! No pending records found to upload.');
      return true;
    }

    log('Sync Engine: Found ${pendingRecords.length} records ready for processing.');
    bool allSyncedSuccessfully = true;

    for (var record in pendingRecords) {
      // Don't sync *today's* rolling live record early; sync only if it's an older day
      final todayString = DateTime.now().toIso8601String().substring(0, 10);
      if (record.dateString == todayString) {
        continue; 
      }

      final success = await _uploadRecord(record);
      if (!success) {
        allSyncedSuccessfully = false;
      }
    }

    return allSyncedSuccessfully;
  }

  Future<bool> _uploadRecord(DailyMetricModel record) async {
    final isar = _db.instance;

    // Update state to syncing immediately to avoid race conditions
    await isar.writeTxn(() async {
      record.syncStatus = 'syncing';
      await isar.dailyMetricModels.put(record);
    });

    try {
      final response = await http.post(
        Uri.parse(AppConstants.syncMetricsEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'date': record.dateString,
          'steps': record.steps,
          'calories': record.calories,
          'distance_km': record.distanceKm,
          'duration_minutes': record.durationMinutes,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('Successfully uploaded records for date: ${record.dateString}');
        
        await isar.writeTxn(() async {
          record.syncStatus = 'synced';
          await isar.dailyMetricModels.put(record);
        });
        return true;
      } else {
        log('Server rejected packet with status code: ${response.statusCode}');
        _markAsFailed(record);
        return false;
      }
    } catch (e) {
      log('Network submission exception for ${record.dateString}: $e');
      _markAsFailed(record);
      return false;
    }
  }

  void _markAsFailed(DailyMetricModel record) async {
    final isar = _db.instance;
    await isar.writeTxn(() async {
      record.syncStatus = 'failed';
      await isar.dailyMetricModels.put(record);
    });
  }
}