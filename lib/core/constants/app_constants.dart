import 'package:flutter/material.dart';

class AppConstants {
  // Suppress constructor to prevent instantiation
  AppConstants._();

  // --- Network & API Endpoints ---
  static const String baseUrl = 'https://api.yourdomain.com/v1';
  static const String syncMetricsEndpoint = '$baseUrl/metrics/sync';

  // --- Local Database Keys ---
  static const String dbName = 'step_up_local_db';
  static const String dailyMetricsBox = 'daily_metrics_box';

  // --- Design Aesthetics (Cyber-Luxury / Bold Layouts) ---
  static const Color primaryAccent = Color(0xFFFF1493); // Pink Giraffe Accent
  static const Color backgroundDark = Color(0x00121212); // Deep Charcoal
  static const Color surfaceGlass = Color(0x1AFFFFFF);  // For Glassmorphic layers
  static const Color textBright = Color(0xFFF5F5F7);   // Crisp iOS text look

  // --- Pedometer & Metric Baselines ---
  static const int defaultStepGoal = 10000;
  static const double averageStrideLengthMeters = 0.762; // Used to estimate distance
  static const double caloriesBurnedPerStep = 0.04;      // Simple metabolic approximation
}

/// Sync Status flags used across Local DB, Repositories, and Sync Engine
enum SyncStatus {
  pending,
  syncing,
  synced,
  failed,
}