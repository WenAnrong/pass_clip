import 'package:flutter/material.dart';
import 'package:pass_clip/services/auth_service.dart';
import 'package:pass_clip/components/bottom_navigation.dart';
import 'package:pass_clip/pages/login.dart';
import 'package:pass_clip/pages/password_setup.dart';

// 初始页面
// 功能：应用启动时的第一个页面，用于检查应用状态并导航到相应的页面
class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  @override
  State<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> {
  // 认证服务实例，用于检查密码设置和登录状态
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // 在组件挂载后立即检查应用初始状态
    _checkInitialState();
  }

  // 优化启动速度：使用微任务队列执行导航逻辑
  Future<void> _checkInitialState() async {
    // 在进入异步块之前获取NavigatorState，避免跨async gap使用context
    final navigatorState = Navigator.of(context);

    // 使用microtask确保在当前事件循环结束后立即执行
    // 这可以提高初始页面的渲染速度
    await Future.microtask(() async {
      try {
        // 执行核心的状态检查和导航逻辑（优先执行）
        await _checkStateAndDoNavigate(navigatorState);
      } catch (e) {
        // 异常情况下仍尝试导航到密码设置页面
        if (mounted) {
          await _pushNamedAndRemoveAll(
            navigatorState: navigatorState,
            routeName: '/passwordSetup',
            arguments: {'isFirstTime': true},
          );
        }
      }
    });
  }

  /// 核心逻辑：校验状态并执行跳转
  Future<void> _checkStateAndDoNavigate(NavigatorState navigatorState) async {
    try {
      // 1. 检查用户是否已设置密码（只做最必要的检查）
      final isPasswordSet = await _authService.isPasswordSet();
      if (!isPasswordSet) {
        // 1.1 未设置密码，跳转到密码设置页面
        await _pushNamedAndRemoveAll(
          navigatorState: navigatorState,
          routeName: '/passwordSetup',
          arguments: {'isFirstTime': true}, // 标记为首次设置密码
        );
      } else {
        // 2. 已设置密码，跳转到登录页面
        await _pushNamedAndRemoveAll(
          navigatorState: navigatorState,
          routeName: '/login',
        );
      }
    } catch (e) {
      // 3. 发生任何异常时，弹出提示让用户确认
      await _handleInitializationError(navigatorState);
    }
  }

  /// 处理初始化错误：弹出提示并让用户确认是否清除数据
  Future<void> _handleInitializationError(NavigatorState navigatorState) async {
    // 先检查widget是否挂载
    if (!mounted) return;

    try {
      // 弹出提示对话框
      final shouldClearData = await showDialog<bool>(
        context: context,
        barrierDismissible: false, // 必须选择一个选项才能关闭
        builder: (context) {
          return AlertDialog(
            title: const Text('初始化错误'),
            content: const Text(
              '应用在启动时遇到了问题。\n\n'
              '这可能是由于数据损坏或密码错误导致的。\n\n'
              '选择"确认"将清除所有数据并重新开始设置密码。\n'
              '选择"取消"将退出应用。',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false); // 取消清除数据
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true); // 确认清除数据
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red, // 警告色
                ),
                child: const Text('确认'),
              ),
            ],
          );
        },
      );

      if (shouldClearData == true) {
        // 用户确认清除数据
        await _authService.clearAllData();
        // 清除数据后跳转到密码设置页面
        if (mounted) {
          await _pushNamedAndRemoveAll(
            navigatorState: navigatorState,
            routeName: '/passwordSetup',
            arguments: {'isFirstTime': true},
          );
        }
      } else {
        // 用户取消清除数据，退出应用
        if (mounted) {
          // 退出当前页面（InitialPage），由于这是第一个页面，应用会退出
          Navigator.pop(context);
        }
      }
    } catch (e) {
      // 发生任何错误时，直接跳转到密码设置页面
      if (mounted) {
        await _pushNamedAndRemoveAll(
          navigatorState: navigatorState,
          routeName: '/passwordSetup',
          arguments: {'isFirstTime': true},
        );
      }
    }
  }

  /// 内部工具方法：清空栈跳转
  Future<void> _pushNamedAndRemoveAll({
    required NavigatorState navigatorState,
    required String routeName,
    dynamic arguments,
  }) async {
    // 关键：跳转前必须检查Widget是否还挂载，避免操作已销毁的页面
    if (!mounted) return;

    try {
      // 1. 优先使用命名路由跳转
      await navigatorState.pushNamedAndRemoveUntil(
        routeName,
        (Route<dynamic> route) => false,
        arguments: arguments,
      );
    } catch (e) {
      // 2. 命名路由跳转失败时，使用备用方案
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

      // 跳转前再次检查mounted
      if (mounted) {
        navigatorState.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => targetPage),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    ); // 初始加载时显示加载动画
  }
}
