import 'package:flutter/material.dart';
import 'package:step_up_clone/core/constants/app_constants.dart';
import 'package:step_up_clone/features/dashboard/presentation/screens/dashboard_screen.dart';

void main() {
  // Ensure native bindings are warm
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const StepUpApp());
}

class StepUpApp extends StatelessWidget {
  const StepUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Step Up Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppConstants.backgroundDark,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppConstants.primaryAccent,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}