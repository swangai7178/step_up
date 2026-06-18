import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart'; 

import 'package:step_up_clone/core/constants/app_constants.dart'; 
import 'package:step_up_clone/features/dashboard/data/repositories/step_repository_impl.dart';
import 'package:step_up_clone/features/dashboard/presentation/controllers/step_tracker_notifier.dart';
import 'package:step_up_clone/features/dashboard/presentation/widgets/daily_ring.dart';
import 'package:step_up_clone/features/dashboard/presentation/widgets/metric_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final StepTrackerNotifier _notifier;
  bool _permissionDeniedMessage = false;

  @override
  void initState() {
    super.initState();
    
    _notifier = StepTrackerNotifier(
      repository: StepRepositoryImpl(),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final status = await Permission.activityRecognition.request();
      if (status.isGranted) {
        _notifier.initializeTracker();
      } else {
        setState(() => _permissionDeniedMessage = true);
        _notifier.initializeTracker();
      }
    });
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StepTrackerNotifier>.value(
      value: _notifier,
      child: Scaffold(
        backgroundColor: AppConstants.backgroundDark,
        body: SafeArea(
          child: Consumer<StepTrackerNotifier>(
            builder: (context, notifier, child) {
              if (notifier.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryAccent),
                  ),
                );
              }

              final metrics = notifier.currentMetrics;
              final steps = metrics?.steps ?? 0;
              final calories = metrics?.calories ?? 0.0;
              final distance = metrics?.distanceKm ?? 0.0;
              final duration = metrics?.durationMinutes ?? 0;
              final progress = metrics?.getProgressPercentage(AppConstants.defaultStepGoal) ?? 0.0;
              
              // Determine if we need to show the top sync banner prompt
              final showSyncPrompt = metrics != null && metrics.isSynced == false;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 👇 NEW FEATURE: SYNC ACTION PROMPT BANNER
                    if (showSyncPrompt) ...[
                      GestureDetector(
                        onTap: notifier.isSyncing 
                            ? null 
                            : () => notifier.syncToFirebase(),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          decoration: BoxDecoration(
                            color: Colors.amberAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.cloud_upload, color: Colors.amberAccent, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Cloud Sync Pending',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      'Tap here to back up today\'s steps safely.',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              notifier.isSyncing 
                                  ? const SizedBox(
                                      height: 20, 
                                      width: 20, 
                                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.amberAccent)),
                                    )
                                  : Icon(Icons.arrow_forward_ios, color: Colors.amberAccent, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'STEP UP',
                              style: TextStyle(
                                color: AppConstants.textBright,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              metrics?.isSynced == true ? 'All logs up to date' : 'Local Logs • Upload Pending',
                              style: TextStyle(
                                color: AppConstants.textBright.withValues(alpha: 0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: metrics?.isSynced == true ? Colors.green.withValues(alpha: 0.2) : Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            metrics?.isSynced == true ? Icons.cloud_done : Icons.cloud_off,
                            color: metrics?.isSynced == true ? Colors.greenAccent : Colors.amberAccent,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    if (_permissionDeniedMessage) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "⚠️ Permission required to access physical sensors. Please enable it in system settings.",
                          style: TextStyle(color: Colors.redAccent, fontSize: 12),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                    Center(
                      child: DailyRing(
                        progress: progress,
                        steps: steps,
                        target: AppConstants.defaultStepGoal,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                        children: [
                          MetricCard(
                            title: 'Distance',
                            value: '${distance.toStringAsFixed(2)} km',
                            icon: Icons.directions_walk,
                          ),
                          MetricCard(
                            title: 'Calories',
                            value: '${calories.toStringAsFixed(0)} kcal',
                            icon: Icons.local_fire_department,
                          ),
                          MetricCard(
                            title: 'Active Time',
                            value: '$duration min',
                            icon: Icons.timer,
                          ),
                          MetricCard(
                            title: 'Today Tracker',
                            value: metrics?.dateString ?? '---',
                            icon: Icons.calendar_today,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}