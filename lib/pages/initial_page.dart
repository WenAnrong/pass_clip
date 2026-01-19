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

  // 加载状态标志，用于显示加载指示器
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 在组件挂载后立即检查应用初始状态
    _checkInitialState();
  }

  // 修复核心：异步操作前先处理context，加mounted检查
  Future<void> _checkInitialState() async {
    // 第一步：先检查Widget是否还挂载（活着），没挂载就直接返回，避免无效操作
    if (!mounted) {
      setState(() => _isLoading = false);
      return;
    }

    // 第二步：在异步操作前获取NavigatorState（避免跨async gap使用context）
    final navigatorState = Navigator.of(context);

    try {
      // 确保每次打开应用，登录状态都是false，必须走校验流程
      await _authService.saveLoginStatus(false);

      // 异步操作后，再次检查mounted（防止操作期间Widget被销毁）
      if (mounted) {
        // 执行核心的状态检查和导航逻辑
        await _checkStateAndDoNavigate(navigatorState);
      }
    } finally {
      // 无论检查结果如何，都停止加载状态（加mounted避免更新已销毁的State）
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 核心逻辑：校验状态并执行跳转
  Future<void> _checkStateAndDoNavigate(NavigatorState navigatorState) async {
    // 先检查导航器是否可用 + Widget是否挂载
    if (!mounted) return;

    try {
      // 1. 检查用户是否已设置密码
      final isPasswordSet = await _authService.isPasswordSet();
      if (!isPasswordSet) {
        // 1.1 未设置密码，跳转到密码设置页面
        await _pushNamedAndRemoveAll(
          navigatorState: navigatorState,
          routeName: '/passwordSetup',
          arguments: {'isFirstTime': true}, // 标记为首次设置密码
        );
      } else {
        // 2. 已设置密码，检查用户是否已登录
        final isLoggedIn = await _authService.getLoginStatus();
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
    return Scaffold(
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text('加载中...'),
      ),
    );
  }
}
