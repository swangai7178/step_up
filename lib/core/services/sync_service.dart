import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:step_up_clone/core/constants/app_constants.dart';
import 'package:step_up_clone/core/database/local_database.dart';
import 'package:step_up_clone/features/dashboard/data/models/daily_metric_model.dart';

class SyncService {
  final LocalDatabase _localDb;

  SyncService({LocalDatabase? db}) : _localDb = db ?? LocalDatabase();

  /// Scans the database for un-synchronized metric blocks from previous days and pushes them.
  Future<bool> syncPendingDays() async {
    try {
      final db = await _localDb.database;
      
      // 1. Fetch records where sync status is 'pending' or 'failed' using standard SQLite query layouts
      final List<Map<String, dynamic>> maps = await db.query(
        'daily_metrics',
        where: "sync_status = ? OR sync_status = ?",
        whereArgs: ['pending', 'failed'],
      );

      if (maps.isEmpty) {
        log('Sync Engine: Complete! No pending records found to upload.');
        return true;
      }

      // Convert raw structural query maps into standard models
      final pendingRecords = maps.map((m) => DailyMetricModel.fromMap(m)).toList();
      log('Sync Engine: Found ${pendingRecords.length} records ready for processing.');
      
      bool allSyncedSuccessfully = true;
      final todayString = DateTime.now().toIso8601String().substring(0, 10);

      for (var record in pendingRecords) {
        // Don't sync *today's* rolling live record early; sync only if it's an older day
        if (record.dateString == todayString) {
          continue; 
        }

        final success = await _uploadRecord(db, record);
        if (!success) {
          allSyncedSuccessfully = false;
        }
      }

      return allSyncedSuccessfully;
    } catch (e) {
      log('Sync Engine runtime processing failure: $e');
      return false;
    }
  }

  Future<bool> _uploadRecord(Database db, DailyMetricModel record) async {
    // Update state to syncing immediately to avoid duplicate race conditions during execution loops
    record.syncStatus = 'syncing';
    await _updateStatusInDatabase(db, record);

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
        
        record.syncStatus = 'synced';
        await _updateStatusInDatabase(db, record);
        return true;
      } else {
        log('Server rejected packet with status code: ${response.statusCode}');
        await _markAsFailed(db, record);
        return false;
      }
    } catch (e) {
      log('Network submission exception for ${record.dateString}: $e');
      await _markAsFailed(db, record);
      return false;
    }
  }

  Future<void> _markAsFailed(Database db, DailyMetricModel record) async {
    record.syncStatus = 'failed';
    await _updateStatusInDatabase(db, record);
  }

  Future<void> _updateStatusInDatabase(Database db, DailyMetricModel record) async {
    await db.update(
      'daily_metrics',
      {'sync_status': record.syncStatus},
      where: 'date_string = ?',
      whereArgs: [record.dateString],
    );
  }
}