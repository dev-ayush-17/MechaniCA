import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../widgets/onboarding_page.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'Trusted Care\nFor Your Ride',
      'description': 'Expert service, genuine parts\nand complete transparency.',
      'icon': Icons.handyman,
    },
    {
      'title': 'Pick, Track & Relax',
      'description': 'We pick your bike, service it\nand drop it back.',
      'icon': Icons.delivery_dining,
    },
    {
      'title': 'Live Tracking\nEvery Step',
      'description': 'Track your bike in real-time\nfrom pickup to delivery.',
      'icon': Icons.map,
    },
  ];

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return OnboardingPageWidget(
                    title: _onboardingData[index]['title'],
                    description: _onboardingData[index]['description'],
                    placeholderIcon: _onboardingData[index]['icon'],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(_currentPage == _onboardingData.length - 1 ? 'Get Started' : 'Next'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? AppTheme.primaryRed : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
