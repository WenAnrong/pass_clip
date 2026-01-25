import 'package:flutter/material.dart';

// 亮色常量
// 主题色常量：#9CCC65
const Color primaryThemeColor = Color(0xFF9CCC65);
// 辅助色常量：#F1F8E9
const Color secondaryThemeColor = Color(0xFFF1F8E9);
// 部分背景色常量：#E8F5E9
const Color backgroundColor = Color(0xFFE8F5E9);

// 暗色常量
// 主题色常量：#66BB6A
const Color darkPrimaryThemeColor = Color(0xFF66BB6A);
// 辅助色常量：#E8F5E9
const Color darkSecondaryThemeColor = Color(0xFFE8F5E9);

// 应用主题配置
final appTheme = ThemeData(
  // 启用Material Design 3
  useMaterial3: true,
  // 字体
  fontFamily: 'NotoSansSC',
  // 基于指定的主题色生成整套协调的颜色体系
  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryThemeColor,
    // 指定主色
    primary: primaryThemeColor,
    // 次要颜色
    secondary: secondaryThemeColor,
    // 主题亮度：浅色模式
    brightness: Brightness.light,
  ),
  // appBar 主题配置
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
  // 显示主题配置
  dialogTheme: DialogThemeData(
    backgroundColor: backgroundColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
  ),
  // 文本按钮主题配置
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: Colors.black87),
  ),
  // 底部导航栏主题配置
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: backgroundColor,
    selectedItemColor: Colors.black87,
    unselectedItemColor: Colors.grey,
  ),
  // 文本输入框主题配置
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0)),
    labelStyle: TextStyle(color: Colors.black87),
    hintStyle: TextStyle(color: Colors.grey),
  ),
);

// 暗色主题配置
final darkAppTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'NotoSansSC',
  colorScheme: ColorScheme.fromSeed(
    seedColor: darkPrimaryThemeColor,
    // 指定主色
    primary: darkPrimaryThemeColor,
    // 次要颜色
    secondary: darkSecondaryThemeColor,
    // 主题亮度：深色模式
    brightness: Brightness.dark,
  ),
);
