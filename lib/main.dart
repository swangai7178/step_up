import 'package:flutter/material.dart';
import 'package:step_up_clone/core/background/background_worker.dart';
import 'package:step_up_clone/core/constants/app_constants.dart';
import 'package:step_up_clone/core/database/local_database.dart';
import 'package:step_up_clone/features/dashboard/presentation/screens/dashboard_screen.dart';

void main() async {
  // 1. Ensure Flutter engine native framework bindings are warm and ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize the centralized Isar Local Database instance
  final localDb = LocalDatabase();
  await localDb.initialize();

  // 3. Register background worker execution loops and schedule task loops
  await BackgroundWorker.initialize();

  // 4. Fire up the application layout thread
  runApp(const StepUpApp());
}

class StepUpApp extends StatelessWidget {
  const StepUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Step Up Tracker',
      debugShowCheckedModeBanner: false,
      
      // Cyber-Luxury / Dark Mode Styling configuration
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppConstants.backgroundDark,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppConstants.primaryAccent,
          surface: AppConstants.backgroundDark,
        ),
        fontFamily: 'Roboto', // Custom fonts can be substituted here seamlessly
      ),
      
      home: const DashboardScreen(),
    );
  }
}