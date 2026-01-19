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
      // 1. 检查用户是否已设置密码
      final isPasswordSet = await authService.isPasswordSet();
      if (!isPasswordSet) {
        // 1.1 未设置密码，跳转到密码设置页面
        await _pushNamedAndRemoveAll(
          navigatorState: navigatorState,
          routeName: '/passwordSetup',
          arguments: {'isFirstTime': true}, // 标记为首次设置密码
        );
      } else {
        // 2. 已设置密码，检查用户是否已登录
        final isLoggedIn = await authService.getLoginStatus();
        if (isLoggedIn) {
          // 2.1 已登录，跳转到应用主界面（底部导航栏）
          await _pushNamedAndRemoveAll(
            navigatorState: navigatorState,
            routeName: '/',
          );
        } else {
          // 2.2 未登录，跳转到登录页面
          await _pushNamedAndRemoveAll(
            navigatorState: navigatorState,
            routeName: '/login',
          );
        }
      }
    } catch (e) {
      // 3. 发生任何异常时，默认跳转到密码设置页面
      await _pushNamedAndRemoveAll(
        navigatorState: navigatorState,
        routeName: '/passwordSetup',
        arguments: {'isFirstTime': true}, // 异常情况下默认视为首次使用
      );
    }
  }

  /// 内部工具方法：清空栈跳转（接收 NavigatorState）
  /// 功能：跳转到指定页面并清除之前所有页面，确保用户无法返回
  static Future<void> _pushNamedAndRemoveAll({
    required NavigatorState navigatorState, // 导航状态对象
    required String routeName, // 目标页面路由名称
    dynamic arguments, // 传递给目标页面的参数
  }) async {
    try {
      // 1. 优先使用命名路由跳转（更简洁高效）
      await navigatorState.pushNamedAndRemoveUntil(
        routeName,
        (Route<dynamic> route) => false, // 路由守卫：false表示清除所有页面
        arguments: arguments,
      );
    } catch (e) {
      // 2. 命名路由跳转失败时（可能路由未注册或其他异常），使用备用方案
      Widget targetPage = const Scaffold(body: Center(child: Text('页面不存在')));

      // 2.1 根据路由名称创建对应的页面组件
      switch (routeName) {
        case '/passwordSetup':
          targetPage = PasswordSetupPage(
            isFirstTime: arguments?['isFirstTime'] ?? true, // 默认为首次设置
          );
          break;
        case '/login':
          targetPage = const LoginPage();
          break;
        case '/':
          targetPage = const BottomNavigation();
          break;
      }

      // 2.2 使用MaterialPageRoute直接跳转
      navigatorState.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => targetPage),
        (route) => false, // 清除所有页面
      );
    }
  }
}
