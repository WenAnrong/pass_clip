import 'package:flutter/material.dart';
import 'package:pass_clip/services/auth_service.dart';
import 'login.dart';
import 'password_setup.dart';

// 应用初始化页面，用于检查登录状态和密码设置
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

  // 检查应用的初始状态
  Future<void> _checkInitialState() async {
    try {
      // 检查是否已设置密码
      final isPasswordSet = await _authService.isPasswordSet();
      if (!isPasswordSet) {
        // 未设置密码，跳转到密码设置页面
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PasswordSetupPage(isFirstTime: true),
          ),
        );
      } else {
        // 已设置密码，检查登录状态
        final isLoggedIn = await _authService.getLoginStatus();
        if (isLoggedIn) {
          // 已登录，跳转到主界面
          Navigator.pushReplacementNamed(context, '/');
        } else {
          // 未登录，跳转到登录页面
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      }
    } catch (e) {
      // 发生错误，默认跳转到密码设置页面
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const PasswordSetupPage(isFirstTime: true),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
