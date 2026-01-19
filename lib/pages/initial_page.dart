import 'package:flutter/material.dart';
import 'package:pass_clip/services/auth_service.dart';
import 'package:pass_clip/components/bottom_navigation.dart';
import 'package:pass_clip/pages/login.dart';
import 'package:pass_clip/pages/password_setup.dart';

class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  @override
  State<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  // 核心：检查状态并跳转（全部清空旧页面）
  Future<void> _checkInitialState() async {
    try {
      final isPasswordSet = await _authService.isPasswordSet();
      if (!isPasswordSet) {
        // 跳密码设置页 → 清空所有旧页面
        await _pushNamedAndRemoveAll(
          '/passwordSetup',
          arguments: {'isFirstTime': true},
        );
      } else {
        final isLoggedIn = await _authService.getLoginStatus();
        if (isLoggedIn) {
          // 跳主界面 → 清空所有旧页面
          await _pushNamedAndRemoveAll('/');
        } else {
          // 跳登录页 → 清空所有旧页面
          await _pushNamedAndRemoveAll('/login');
        }
      }
    } catch (e) {
      // 异常兜底 → 跳密码设置页并清空所有
      await _pushNamedAndRemoveAll(
        '/passwordSetup',
        arguments: {'isFirstTime': true},
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 封装：清空所有旧页面，跳转到指定命名路由（核心方法）
  /// [routeName]：目标路由名（比如'/login'）
  /// [arguments]：传递给目标页面的参数
  Future<void> _pushNamedAndRemoveAll(
    String routeName, {
    dynamic arguments,
  }) async {
    try {
      // 关键：pushNamedAndRemoveUntil + predicate返回false → 清空所有旧路由
      await Navigator.pushNamedAndRemoveUntil(
        context,
        routeName,
        (Route<dynamic> route) => false, // 核心参数：false=移除所有之前的路由
        arguments: arguments, // 传递参数
      );
    } catch (e) {
      // 路由跳转失败（比如拼错名）→ 兜底跳转（仍清空所有）
      print('路由跳转失败：$routeName，错误：$e');
      Widget page = const Scaffold(body: Center(child: Text('页面不存在')));
      if (routeName == '/passwordSetup') {
        page = PasswordSetupPage(
          isFirstTime: arguments?['isFirstTime'] ?? true,
        );
      } else if (routeName == '/login') {
        page = const LoginPage();
      } else if (routeName == '/') {
        page = const BottomNavigation();
      }
      // 非命名路由版：清空所有并跳转
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => page),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text('加载中...'),
      ),
    );
  }
}
