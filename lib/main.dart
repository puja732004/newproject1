import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:newproject1/screens/userlogin/loginpage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyBl_AdjYpLVAayz-6fQW_ezpvFnV1QIxZs",
      appId: "1:261066429876:android:39ab7b4c6df328be528ee1",
      messagingSenderId: "261066429876",
      projectId: "learnee-d191f",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: Loginpage());
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background color
      body: Center(
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
            children: [
              TextSpan(
                text: 'Zylo',
                style: TextStyle(
                  color: Colors.deepPurple.shade400,
                ),
              ),
              const TextSpan(
                text: 'Mart',
                style: TextStyle(
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
