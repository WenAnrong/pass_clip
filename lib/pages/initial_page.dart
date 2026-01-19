import 'package:flutter/material.dart';
import 'package:pass_clip/services/auth_service.dart';
import 'package:pass_clip/utils/app_navigator_utils.dart';

/*
 * 初始页面
 * 负责检查登录状态并导航到对应页面
 */

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

  Future<void> _checkInitialState() async {
    try {
      // 核心修正：直接获取当前上下文的 NavigatorState，无需手动赋值 GlobalKey
      final navigatorState = Navigator.of(context);
      // 调用工具类的重载方法（传 NavigatorState）
      await AppNavigatorUtils.checkAppStateAndNavigateWithState(
        navigatorState: navigatorState,
        authService: _authService,
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
