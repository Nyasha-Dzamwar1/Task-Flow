import 'package:flutter/material.dart';
import 'package:mapd/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'services/app_repository.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppRepository(), //Register AppRepository here
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Task Flow',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: LoginScreen(),
      ),
    );
  }
}
