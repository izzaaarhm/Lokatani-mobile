import 'package:flutter/material.dart';
import '../pages/login.dart';
import '../pages/register.dart';
import '../pages/change_pass.dart';
import '../pages/dashboard.dart';
import '../pages/weighing.dart';
import '../pages/profile.dart';
import '../pages/edit_profile.dart';
import '../pages/history.dart';
import '../pages/weighing_detail.dart';

class Routes {
  static const String login = '/';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
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
      forgotPassword: (context) => const ChangePasswordScreen(),
      dashboard: (context) => const DashboardScreen(),
      addWeighing: (context) => const WeighingPage(),
      profile: (context) => const ProfileScreen(),
      history: (context) => const HistoryScreen(),
      weighingDetail: (context) => const WeighingDetailScreen(),
      editProfile: (context) => const EditProfileScreen(),
      // tutorial: (context) => const TutorialScreen(),
    };
  }
}