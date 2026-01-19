import 'package:flutter/material.dart';
import 'package:pass_clip/routers/index.dart';
import 'package:pass_clip/theme/index.dart';

void main() {
  runApp(const MyApp());
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
      title: '秘荚', // 应用名称
      initialRoute: '/initial', // 初始路由（首次启动时的页面，这里会做密码校验）
      routes: AppRouter.routes, // 应用路由配置
      // 全局主题配置
      theme: appTheme,
      // 暗色主题配置
      darkTheme: darkAppTheme,
      // 主题模式：跟随系统设置（推荐）
      themeMode: ThemeMode.system,
    );
  }
}
