import 'package:flutter/material.dart';
import 'package:pass_clip/components/bottom_navigation.dart';
import 'package:pass_clip/pages/home.dart';
import 'package:pass_clip/pages/initial_page.dart';
import 'package:pass_clip/pages/add_account.dart';
import 'package:pass_clip/pages/account_detail.dart';
import 'package:pass_clip/pages/profile.dart';
import 'package:pass_clip/pages/category_management.dart';
import 'package:pass_clip/pages/login.dart';
import 'package:pass_clip/pages/password_setup.dart';
import 'package:pass_clip/pages/webdav_page.dart';

class AppRouter {
  static Map<String, WidgetBuilder> routes = {
    '/': (context) => const BottomNavigation(),
    '/initial': (context) => const InitialPage(),
    '/home': (context) => const HomePage(),
    '/addAccount': (context) => const AddAccountPage(),
    '/profile': (context) => const ProfilePage(),
    '/accountDetail': (context) => const AccountDetailPage(),
    '/categoryManagement': (context) => const CategoryManagementPage(),
    '/login': (context) => const LoginPage(),
    '/passwordSetup': (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return PasswordSetupPage(isFirstTime: args?['isFirstTime'] ?? false);
    },
    '/webdav': (context) => const WebDAVPage(),
  };
}
