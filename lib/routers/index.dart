import 'package:flutter/material.dart';
import 'package:pass_clip/components/bottom_navigation.dart';
import 'package:pass_clip/models/account.dart';
import 'package:pass_clip/pages/about.dart';
import 'package:pass_clip/pages/home.dart';
import 'package:pass_clip/pages/initial_page.dart';
import 'package:pass_clip/pages/account_management.dart';
import 'package:pass_clip/pages/account_detail.dart';
import 'package:pass_clip/pages/profile.dart';
import 'package:pass_clip/pages/category_management.dart';
import 'package:pass_clip/pages/login.dart';
import 'package:pass_clip/pages/password_setup.dart';
import 'package:pass_clip/pages/webdav_page.dart';
import 'package:pass_clip/pages/password_generator_page.dart';

class AppRouter {
  static Map<String, WidgetBuilder> routes = {
    '/': (context) => const BottomNavigation(),
    '/initial': (context) => const InitialPage(),
    '/home': (context) => const HomePage(),
    '/addAccount': (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Account?;
      return AccountManagementPage(account: args);
    },
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
    '/passwordGenerator': (context) => const PasswordGeneratorPage(),
    '/about': (context) => const About(),
  };
}
