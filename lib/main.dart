import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 👈 Added Firebase Core
import 'package:step_up_clone/core/constants/app_constants.dart';
import 'package:step_up_clone/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'firebase_options.dart'; // 👈 Added the generated FlutterFire options file

void main() async {
  // 1. Ensure native platform engine bindings are warm and ready
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
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