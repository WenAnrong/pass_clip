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
    brightness: Brightness.light,
  ),
  // 让AppBar、按钮等组件默认继承主题色
  appBarTheme: AppBarTheme(
    backgroundColor: primaryThemeColor,
    foregroundColor: Colors.black87, // 文字/图标颜色（适配浅主题色）
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryThemeColor,
      foregroundColor: Colors.black87,
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
