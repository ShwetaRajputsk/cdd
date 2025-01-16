import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "image": "assets/healthcheck.png",
      "title": "Health Check",
      "description": "Take a picture of your crop or upload an image to detect diseases and receive treatment advice."
    },
    {
      "image": "assets/community.png",
      "title": "Community",
      "description": "Ask a question about your crop to receive help from the community."
    },
    {
      "image": "assets/cultivationtips.png",
      "title": "Cultivation Tips",
      "description": "Receive farming advice about how to improve your yield."
    },
  ];

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: onboardingData.length,
                itemBuilder: (context, index) => OnboardingContent(
                  image: onboardingData[index]["image"]!,
                  title: onboardingData[index]["title"]!,
                  description: onboardingData[index]["description"]!,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      onboardingData.length,
                      (index) => buildDot(index),
                    ),
                  ),
                  Spacer(),
_currentPage == onboardingData.length - 1
    ? ElevatedButton(
        onPressed: () {
          Navigator.pushReplacementNamed(context, '/login');  // Change here
        },
        child: Text("Get Started"),
      )
    : TextButton(
        onPressed: () {
          _pageController.nextPage(
            duration: Duration(milliseconds: 300),
            curve: Curves.ease,
          );
        },
        child: Text("Next"),
      ),
Spacer(),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      margin: EdgeInsets.only(right: 5),
      height: 10,
      width: _currentPage == index ? 20 : 10,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.green : Colors.grey,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  final String image, title, description;

  const OnboardingContent({
    required this.image,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Spacer(),
        Image.asset(
          image,
          height: 300,
        ),
        Spacer(),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Text(
          description,
          textAlign: TextAlign.center,
        ),
        Spacer(),
      ],
    );
  }
}
