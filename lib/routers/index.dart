import 'package:flutter/material.dart';
import '../pages/home.dart';
import '../pages/add_account.dart';
import '../pages/profile.dart';
import '../pages/account_detail.dart';
import '../pages/category_management.dart';
import '../pages/login.dart';
import '../pages/password_setup.dart';
import '../components/bottom_navigation.dart';

class AppRouter {
  static Map<String, WidgetBuilder> routes = {
    '/': (context) => const BottomNavigation(),
    '/home': (context) => const HomePage(),
    '/addAccount': (context) => const AddAccountPage(),
    '/profile': (context) => const ProfilePage(),
    '/accountDetail': (context) => const AccountDetailPage(),
    '/categoryManagement': (context) => const CategoryManagementPage(),
    '/login': (context) => const LoginPage(),
    '/passwordSetup': (context) => const PasswordSetupPage(),
  };
}
