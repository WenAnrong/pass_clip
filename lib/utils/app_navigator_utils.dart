import 'package:flutter/material.dart';
import 'package:pass_clip/services/auth_service.dart';
import 'package:pass_clip/components/bottom_navigation.dart';
import 'package:pass_clip/pages/login.dart';
import 'package:pass_clip/pages/password_setup.dart';

class AppNavigatorUtils {
  /// 重载1：通过 GlobalKey 跳转（给 main.dart 用，已绑定 MaterialApp）
  static Future<void> checkAppStateAndNavigate({
    required GlobalKey<NavigatorState> navigatorKey,
    required AuthService authService,
  }) async {
    if (navigatorKey.currentState == null) {
      return;
    }
    await _checkStateAndDoNavigate(navigatorKey.currentState!, authService);
  }

  /// 重载2：直接接收 NavigatorState（给 InitialPage 用，无需 GlobalKey）
  static Future<void> checkAppStateAndNavigateWithState({
    required NavigatorState navigatorState,
    required AuthService authService,
  }) async {
    await _checkStateAndDoNavigate(navigatorState, authService);
  }

  /// 核心逻辑：校验状态并执行跳转（内部私有方法）
  static Future<void> _checkStateAndDoNavigate(
    NavigatorState navigatorState,
    AuthService authService,
  ) async {
    try {
      final isPasswordSet = await authService.isPasswordSet();
      if (!isPasswordSet) {
        await _pushNamedAndRemoveAll(
          navigatorState: navigatorState,
          routeName: '/passwordSetup',
          arguments: {'isFirstTime': true},
        );
      } else {
        final isLoggedIn = await authService.getLoginStatus();
        if (isLoggedIn) {
          await _pushNamedAndRemoveAll(
            navigatorState: navigatorState,
            routeName: '/',
          );
        } else {
          await _pushNamedAndRemoveAll(
            navigatorState: navigatorState,
            routeName: '/login',
          );
        }
      }
    } catch (e) {
      await _pushNamedAndRemoveAll(
        navigatorState: navigatorState,
        routeName: '/passwordSetup',
        arguments: {'isFirstTime': true},
      );
    }
  }

  /// 内部工具方法：清空栈跳转（接收 NavigatorState）
  static Future<void> _pushNamedAndRemoveAll({
    required NavigatorState navigatorState,
    required String routeName,
    dynamic arguments,
  }) async {
    try {
      await navigatorState.pushNamedAndRemoveUntil(
        routeName,
        (Route<dynamic> route) => false,
        arguments: arguments,
      );
    } catch (e) {
      Widget targetPage = const Scaffold(body: Center(child: Text('页面不存在')));
      switch (routeName) {
        case '/passwordSetup':
          targetPage = PasswordSetupPage(
            isFirstTime: arguments?['isFirstTime'] ?? true,
          );
          break;
        case '/login':
          targetPage = const LoginPage();
          break;
        case '/':
          targetPage = const BottomNavigation();
          break;
      }
      navigatorState.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => targetPage),
        (route) => false,
      );
    }
  }
}
