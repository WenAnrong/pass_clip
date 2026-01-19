import 'package:flutter/material.dart';
import 'routers/index.dart';
import 'services/auth_service.dart';

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


