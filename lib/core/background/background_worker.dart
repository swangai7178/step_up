import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:step_up_clone/core/database/local_database.dart';
import 'package:step_up_clone/core/services/sync_service.dart';
import 'package:workmanager/workmanager.dart';

/// Name of the unique background task for syncing daily steps
const String kDailySyncTask = "com.your_app.dailySyncTask";

class BackgroundWorker {
  
  /// Initializes the background execution configuration.
  /// Call this in your main.dart file before runApp().
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    
    // Schedule the unique periodic task to check at the end of the day
    await Workmanager().registerPeriodicTask(
      "1", 
      kDailySyncTask,
      frequency: const Duration(hours: 6), // OS throttles strict midnight tasks; 6hr intervals ensure catch-up
      constraints: Constraints(
        networkType: NetworkType.connected, // Required: Must have internet connection to sync
        requiresBatteryNotLow: true,        // Required: Prevents battery drain on low levels
      ),
    );
    
    log('Background Worker System Initialized and Scheduled');
  }
}

/// Top-level global function required by background execution plugins.
/// This acts as an entirely isolated entry point when the OS wakes the app up.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    log("Background execution triggered for task: $taskName");
    
    if (taskName == kDailySyncTask) {
      try {
        // 1. Instantiating the helper is enough. 
        // SyncService internally calls and awaits 'db.database' which boots up SQLite cleanly.
        final db = LocalDatabase();
        
        // 2. Fetch data that belongs to completed days but hasn't synced yet
        final syncService = SyncService(db: db);
        final success = await syncService.syncPendingDays();
        
        return success; 
        
      } catch (e) {
        log("Background task execution failed: $e");
        return false;
      }
    }
    return true;
  });
}