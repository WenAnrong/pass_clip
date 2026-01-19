import 'package:flutter/material.dart';
import 'package:pass_clip/routers/index.dart';
import 'package:pass_clip/services/auth_service.dart';

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

  @override
  void initState() {
    super.initState();
    // 注册：把当前页面加入“监听列表”，开始接收应用状态变化通知
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // 移除：页面销毁时取消监听，避免内存泄漏
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 注册了 WidgetsBindingObserver 后，会自动调用此方法, 应用状态变化时会调用此方法
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 在应用进入后台、暂停或完全退出时，清除登录状态
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // 应用退出或进入后台时，清除登录状态
      _authService.saveLoginStatus(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '账号密码管理',
      initialRoute: '/initial',
      routes: AppRouter.routes,
    );
  }
}
