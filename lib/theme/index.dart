import 'package:flutter/material.dart';

// 主题色常量：#fee497
const Color primaryThemeColor = Color(0xFFfee497);

// 应用主题配置
final appTheme = ThemeData(
  // 启用Material Design 3
  useMaterial3: true,
  // 基于指定的主题色生成整套协调的颜色体系
  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryThemeColor,
    // 显式指定主色（确保核心色为#fee497）
    primary: primaryThemeColor,
    // 次要颜色（确保与主色协调）
    secondary: Color(0xFF5a272c),
    // 主题亮度：浅色模式
    brightness: Brightness.light,
  ),
  // 让AppBar、按钮等组件默认继承主题色
  appBarTheme: AppBarTheme(
    backgroundColor: primaryThemeColor,
    foregroundColor: Colors.black87, // 文字/图标颜色（适配浅主题色）
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    //  elevatedButton 主题配置
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryThemeColor,
      foregroundColor: Colors.black87,
    ),
  ),
  // 文本主题配置
  textTheme: TextTheme(
    //  bodyLarge 主题配置
    bodyLarge: TextStyle(
      color: Colors.black87, // 文字颜色（适配浅主题色）
    ),
  ),
);

// 暗色主题配置
final darkAppTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryThemeColor,
    brightness: Brightness.dark,
  ),
);
