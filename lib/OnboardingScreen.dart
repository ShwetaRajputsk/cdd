import 'package:flutter/material.dart';
import 'login.dart';
import 'home_page.dart';

void main() {
  runApp(const PlantApp());
}

class PlantApp extends StatelessWidget {
  const PlantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CropFit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1C4B0C),
          primary: const Color(0xFF1C4B0C),
        ),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomePage(),
      },
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top left plant image
          Positioned(
            top: 0,
            left: 0,
            child: Image.asset(
              'assets/images/top_plant.png',
              width: MediaQuery.of(context).size.width * 0.7,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if image is not available
                return Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: 300,
                  color: Colors.transparent,
                );
              },
            ),
          ),

          // Bottom right succulents
          Positioned(
            bottom: 0,
            right: 0,
            child: Image.asset(
              'assets/images/bottom_succulents.png',
              width: MediaQuery.of(context).size.width * 0.8,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if image is not available
                return Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: 400,
                  color: Colors.transparent,
                );
              },
            ),
          ),

          // Center content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  // Title with colored "plant" word
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                      children: [
                        const TextSpan(text: "Grow "),
                        TextSpan(
                          text: "Smarter",
                          style: TextStyle(
                            color: const Color(0xFF1C4B0C),
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const TextSpan(text: ", Farm "),
                        TextSpan(
                          text: "Better",
                          style: TextStyle(
                            color: const Color(0xFF1C4B0C),
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const TextSpan(text: " With "),
                        TextSpan(
                          text: "CropFit",
                          style: TextStyle(
                            color: const Color(0xFF1C4B0C),
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const TextSpan(text: " !!"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      "Detect crop diseases instantly, get pro farming tips, and boost your harvest — all in one app.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[800],
                            fontSize: 18,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Get Started button with arrows
                  Padding(
                    padding: const EdgeInsets.only(right: 50.0, left: 90.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C4B0C),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.pushReplacementNamed(
                                    context, '/login');
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                child: Text(
                                  "Get Started",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Double chevron arrows outside button
                        Stack(
                          children: const [
                            Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Icon(
                                Icons.chevron_right,
                                size: 24,
                                color: Color(0xFF1C4B0C),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 24,
                              color: Color(0xFF1C4B0C),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Welcome to Plant App",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                "Discover the joy of plants and how they can improve your life, home, and wellbeing.",
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.chevron_left, color: Color(0xFF5A8A5E)),
                label: const Text(
                  "Back to home",
                  style: TextStyle(color: Color(0xFF5A8A5E)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
