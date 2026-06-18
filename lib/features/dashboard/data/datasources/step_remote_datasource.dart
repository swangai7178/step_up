import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:step_up_clone/core/constants/app_constants.dart';
import 'package:step_up_clone/features/dashboard/data/models/daily_metric_model.dart';

class StepRemoteDatasource {
  final http.Client _client;

  StepRemoteDatasource({http.Client? client}) : _client = client ?? http.Client();

  /// Transmits a single day's metric block directly to the remote server architecture.
  /// Throws an exception if the server rejects the network payload.
  Future<void> uploadDailyMetrics(DailyMetricModel metrics) async {
    final url = Uri.parse(AppConstants.syncMetricsEndpoint);
    
    try {
      log('Remote Datasource: Outbound request initializing for date: ${metrics.dateString}');
      
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // If using authorization headers later, add them securely here:
          // 'Authorization': 'Bearer \$token',
        },
        body: jsonEncode({
          'date': metrics.dateString,
          'steps': metrics.steps,
          'calories': metrics.calories,
          'distance_km': metrics.distanceKm,
          'duration_minutes': metrics.durationMinutes,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('Remote Datasource: Transfer success for ${metrics.dateString}');
      } else {
        log('Remote Datasource Failure: Server responded with status code ${response.statusCode}');
        throw Exception('Server rejected metric sync upload package.');
      }
    } catch (e) {
      log('Remote Datasource Exception: Network pipeline error occurred -> $e');
      rethrow;
    }
  }
}