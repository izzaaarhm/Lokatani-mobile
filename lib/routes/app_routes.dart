import 'package:flutter/material.dart';
import '../pages/login.dart';
import '../pages/register.dart';
import '../pages/weighing.dart';
import '../pages/edit_profile.dart';
import '../pages/weighing_detail.dart';
import '../pages/main_navigation.dart';

class Routes {
  static const String login = '/';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String history = '/history';
  static const String addWeighing = '/add-weighing';
  static const String weighingDetail = '/weighing-detail';
  static const String tutorial = '/tutorial';
  static const String editProfile = '/edit-profile';
  
  // Add all routes here for easy access
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),

      // Use MainNavigationScreen for dashboard, profile, and history
      dashboard: (context) => const MainNavigationScreen(),
      profile: (context) => const MainNavigationScreen(),
      history: (context) => const MainNavigationScreen(),
      addWeighing: (context) => const WeighingPage(),
      weighingDetail: (context) => const WeighingDetailScreen(),
      editProfile: (context) => const EditProfileScreen(),
      // tutorial: (context) => const TutorialScreen(),
    };
  }
}