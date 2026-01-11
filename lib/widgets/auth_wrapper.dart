import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapd/services/auth_service.dart'; // Your AuthService
import 'package:mapd/services/app_repository.dart'; // Your repo
import 'package:mapd/screens/home_screen.dart'; // Adjust path
import 'package:mapd/screens/login_screen.dart'; // Your login screen (create if missing)
import 'package:mapd/screens/add_edit_task_screen.dart'; // If needed for routes

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthService(),
        ), // AuthService as provider
        ChangeNotifierProvider(create: (_) => AppRepository()), // Your repo
        // Add other providers if needed
      ],
      child: MaterialApp(
        title: 'Your App',
        theme: ThemeData(primarySwatch: Colors.blue), // Customize
        // home: AuthWrapper(),  // If no routes
        routes: {
          '/': (context) => AuthWrapper(), // Root: AuthWrapper
          '/home': (context) => HomeScreen(),
          '/login': (context) => LoginScreen(), // Your login screen
          '/add-task': (context) => AddEditTaskScreen(), // Example
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// AuthWrapper: Auto-redirects based on auth state (fixes post-logout queries)
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(
      context,
    ); // Listen to auth changes

    return StreamBuilder<User?>(
      stream: authService.authStateChanges, // Triggers on login/logout
      builder: (context, snapshot) {
        print(
          'DEBUG: AuthWrapper - Auth state: ${snapshot.connectionState}',
        ); // Debug
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('DEBUG: AuthWrapper - Waiting for auth...');
          return Scaffold(
            body: Center(child: CircularProgressIndicator()), // Splash/loading
          );
        }
        if (snapshot.hasData) {
          final user = snapshot.data!;
          print(
            'DEBUG: AuthWrapper - User signed in: ${user.uid} - Showing HomeScreen',
          );
          return HomeScreen(); // Or your main app screen
        } else {
          print(
            'DEBUG: AuthWrapper - No user (logged out) - Showing LoginScreen',
          );
          return LoginScreen(); // Redirect to login
        }
      },
    );
  }
}
