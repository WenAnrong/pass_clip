import 'package:flutter/material.dart';
import 'package:pass_clip/routers/index.dart';
import 'package:pass_clip/services/auth_service.dart';
import 'package:pass_clip/utils/app_navigator_utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  // 全局导航Key（传给工具类用于跳转）
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  // 防止重复跳转的标记
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 监听应用生命周期
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      // 加入 inactive 状态（多任务界面触发）
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        // 异步方法必须加 await，确保状态清除完成
        _clearLoginStatus();
        break;
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  // 单独封装清除登录状态的异步方法
  Future<void> _clearLoginStatus() async {
    await _authService.saveLoginStatus(false);
  }

  Future<void> _handleAppResumed() async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      // 延迟 100ms 执行，避免状态同步问题
      await Future.delayed(const Duration(milliseconds: 100));
      await AppNavigatorUtils.checkAppStateAndNavigate(
        navigatorKey: _navigatorKey,
        authService: _authService,
      );
    } catch (e) {
      // 保留空 catch 块兜底
    } finally {
      // 无论成功/失败，都重置标记
      _isNavigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '账号密码管理',
      initialRoute: '/initial',
      routes: AppRouter.routes,
      // 绑定全局导航Key（必须）
      navigatorKey: _navigatorKey,
    );
  }
}
