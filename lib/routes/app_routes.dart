import 'package:flutter/material.dart';
import '/screens/screens.dart';

class AppRoutes {
  static const String home = "/";
  static const int homeIndex = 0;
  static const String onBoarding = "/onboarding";
  static const int onBoardingIndex = 1;
  static const String downloads = "/downloads";
  static const int downloadsIndex = 2;
  static const String about = "/about";
  static const int aboutIndex = 2;

  static final Map<String, WidgetBuilder> routes = {
    home: (context) => const HomeScreen(),
    onBoarding: (context) => const OnBoardingScreen(),
    downloads: (context) => const DownloadedModelScreen(),
    about: (context) => const AboutScreen(),
  };
}
