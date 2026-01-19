import 'package:flutter/material.dart';
import 'package:pass_clip/services/auth_service.dart';
import 'package:pass_clip/utils/app_navigator_utils.dart';

/// 初始页面
/// 功能：应用启动时的第一个页面，用于检查应用状态并导航到相应的页面
/// 作用：避免直接在main.dart中处理复杂的初始化逻辑
class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  @override
  State<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> {
  /// 认证服务实例，用于检查密码设置和登录状态
  final AuthService _authService = AuthService();

  /// 加载状态标志，用于显示加载指示器
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 在组件挂载后立即检查应用初始状态
    _checkInitialState();
  }

  /// 检查应用初始状态并导航到相应页面
  Future<void> _checkInitialState() async {
    try {
      // 1. 获取当前页面的导航状态对象
      final navigatorState = Navigator.of(context);

      // 2. 调用导航工具类的方法进行状态检查和导航
      // 使用checkAppStateAndNavigateWithState方法（直接接收NavigatorState）
      await AppNavigatorUtils.checkAppStateAndNavigateWithState(
        navigatorState: navigatorState,
        authService: _authService,
      );
    } finally {
      // 3. 无论检查结果如何，都停止加载状态
      // 注意：这里的setState不会重新构建UI，因为页面会被导航工具类替换
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // 根据加载状态显示不同内容
        child: _isLoading
            ? const CircularProgressIndicator() // 加载中显示进度指示器
            : const Text('加载中...'), // 加载完成后显示提示文本（实际上很少会看到）
      ),
    );
  }
}
