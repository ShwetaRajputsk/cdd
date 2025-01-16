import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Screen imports
import 'splash_screen.dart';
import 'camera_screen.dart';
import 'onboardingscreen.dart';
import 'login.dart';
import 'signup.dart';
import 'home_page.dart';
import 'select_your_crop_page.dart';
import 'disease_detect.dart';
import 'edit_profile.dart';
import 'account.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CropFit - Crop Disease Detection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
         fontFamily: 'Roboto', // Set the global font family
      ),
      home: AuthFlow(), // Updated home to AuthFlow for better handling
      routes: {
        '/onboarding': (context) => OnboardingScreen(),
        '/home': (context) => HomePage(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/selectYourCrop': (context) => SelectYourCropPage(selectedCrops: [],),
        '/diseaseDetect': (context) => CropDiseaseHome(),
        '/account': (context) => AccountPage(),
        '/editProfile': (context) => EditProfilePage(),
      },
    );
  }
}

/// A widget to handle the authentication flow.
class AuthFlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show splash screen while waiting for connection
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }

        // Navigate to HomePage if user is signed in
        if (snapshot.hasData) {
          return HomePage();
        }

        // Navigate to OnboardingScreen if no user is signed in
        return OnboardingScreen();
      },
    );
  }
}
