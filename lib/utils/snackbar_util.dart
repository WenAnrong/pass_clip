import 'package:flutter/material.dart';

/// 全局统一的SnackBar工具类
/// 功能：底部显示文本提示，2秒自动消失，样式全局统一，适配桌面端
class SnackBarUtil {
  // 私有构造函数，禁止实例化
  SnackBarUtil._();

  /// 显示全局统一样式的SnackBar
  /// [context]：当前上下文（必须是MaterialApp内的上下文）
  /// [message]：需要显示的提示文本
  static void show(BuildContext context, String message) {
    // 先关闭当前可能存在的SnackBar，避免叠加
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // 获取屏幕尺寸，适配桌面端
    final screenSize = MediaQuery.of(context).size;
    // 桌面端（宽度>600px）限制SnackBar宽度，移动端自适应
    final double maxWidth = screenSize.width > 600
        ? 400
        : screenSize.width - 40;

    // 构建全局统一样式的SnackBar
    final snackBar = SnackBar(
      /// 核心样式配置（全局统一）
      content: Container(
        width: maxWidth,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.2,
          ),
        ),
      ),
      backgroundColor: Colors.grey[800], // 全局统一背景色
      elevation: 6, // 阴影，增强视觉层次
      behavior: SnackBarBehavior.floating, // 悬浮模式，适配桌面端窗口
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // 全局统一圆角
      ),
      margin: EdgeInsets.only(
        bottom: 20, // 距离底部边距
        left: (screenSize.width - maxWidth) / 2, // 水平居中
        right: (screenSize.width - maxWidth) / 2,
      ),
      duration: const Duration(seconds: 2), // 固定2秒自动消失
      // 禁用行为按钮（仅显示文本）
      action: null,
    );

    // 显示SnackBar
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
