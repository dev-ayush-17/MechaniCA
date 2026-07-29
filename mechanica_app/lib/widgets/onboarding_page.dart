import 'package:flutter/material.dart';

class OnboardingPageWidget extends StatelessWidget {
  final String title;
  final String description;
  final IconData placeholderIcon;

  const OnboardingPageWidget({
    super.key,
    required this.title,
    required this.description,
    required this.placeholderIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 48),
          // Using a large icon as placeholder for the main image
          Icon(placeholderIcon, size: 250, color: Colors.white24),
        ],
      ),
    );
  }
}
