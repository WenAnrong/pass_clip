import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pass_clip/routers/index.dart';
import 'package:pass_clip/theme/index.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

// 定义全局 NavigatorKey
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // 设置应用只支持竖屏
  WidgetsFlutterBinding.ensureInitialized();

  // 只有在桌面平台上才初始化窗口管理器
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // 初始化窗口管理器
    await windowManager.ensureInitialized();

    // 设置窗口大小限制，使其类似手机那样的显示界面
    WindowOptions windowOptions = WindowOptions(
      size: Size(400, 800), // iPhone 11 Pro Max 尺寸
      minimumSize: Size(350, 700), // 最小尺寸
      maximumSize: Size(500, 850), // 最大尺寸，不允许拉长
      center: true,
      title: "秘荚",
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
    });
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '秘荚', // 应用名称
      initialRoute: '/initial', // 初始路由（首次启动时的页面，这里会做密码校验）
      routes: AppRouter.routes, // 应用路由配置
      // 全局主题配置
      theme: appTheme,
      // 暗色主题配置
      darkTheme: darkAppTheme,
      // 主题模式：跟随系统设置
      themeMode: ThemeMode.system,
      // 添加全局 navigatorKey
      navigatorKey: appNavigatorKey,
      // 配置 FToastBuilder（toast 挂载必备）
      builder: FToastBuilder(),
    );
  }
}
