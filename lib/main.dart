import 'package:flutter/material.dart';
import 'package:pass_clip/routers/index.dart';
import 'package:pass_clip/services/auth_service.dart';
import 'package:pass_clip/utils/app_navigator_utils.dart';

/// 应用入口点
void main() {
  runApp(const MyApp());
}

/// 应用根组件
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

/// 应用状态管理类
/// 功能：管理应用生命周期、全局导航和登录状态
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  /// 认证服务实例，用于管理登录状态
  final AuthService _authService = AuthService();

  /// 全局导航Key（用于在任何地方进行页面跳转）
  /// 作用：允许在没有BuildContext的情况下执行导航操作
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  /// 防止重复跳转的标记
  /// 作用：避免在应用恢复时多次触发导航操作
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    // 注册应用生命周期观察者
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // 移除应用生命周期观察者
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 监听应用生命周期变化
  /// 作用：根据应用状态自动管理登录状态和导航
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      // inactive状态：应用处于前台但不可交互（如收到电话）
      // paused状态：应用处于后台
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        // 当应用进入后台或不可交互时，清除登录状态
        // 注意：这里没有使用await，因为我们不希望阻塞UI线程
        // 但在实际生产环境中，可能需要考虑添加适当的错误处理
        _clearLoginStatus();
        break;
      // resumed状态：应用回到前台并可交互
      case AppLifecycleState.resumed:
        // 当应用回到前台时，检查当前状态并导航到相应页面
        _handleAppResumed();
        break;
      // detached状态：应用与平台分离（如进程终止前）
      // hidden状态：应用完全隐藏
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// 清除登录状态
  /// 作用：当应用进入后台时，确保用户需要重新验证身份
  Future<void> _clearLoginStatus() async {
    await _authService.saveLoginStatus(false);
  }

  /// 处理应用恢复到前台的逻辑
  /// 作用：当应用从后台回到前台时，检查登录状态并导航到相应页面
  Future<void> _handleAppResumed() async {
    // 防止重复触发导航操作
    if (_isNavigating) return;

    // 设置导航中标记
    _isNavigating = true;

    try {
      // 延迟100ms执行，避免状态同步问题
      // 原因：应用刚恢复时，可能有些状态还未完全同步
      await Future.delayed(const Duration(milliseconds: 100));

      // 调用导航工具类检查应用状态并执行跳转
      await AppNavigatorUtils.checkAppStateAndNavigate(
        navigatorKey: _navigatorKey, // 传入全局导航Key
        authService: _authService, // 传入认证服务实例
      );
    } catch (e) {
      // 保留空catch块兜底，防止应用崩溃
      // 注意：在生产环境中，应该添加适当的错误日志记录
    } finally {
      // 无论成功或失败，都重置导航标记
      _isNavigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '账号密码管理', // 应用名称
      initialRoute: '/initial', // 初始路由（第一个显示的页面）
      routes: AppRouter.routes, // 应用路由配置
      navigatorKey: _navigatorKey, // 绑定全局导航Key
    );
  }
}
