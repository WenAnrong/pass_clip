import 'dart:async';
import 'package:flutter/material.dart';

class SnackBarManager {
  static final SnackBarManager _instance = SnackBarManager._internal();
  factory SnackBarManager() => _instance;

  SnackBarManager._internal();

  String? _currentMessage;
  Timer? _currentTimer;
  OverlayEntry? _currentOverlay;

  void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    // 检查是否为相同消息，如果是则不重复显示
    if (message == _currentMessage) {
      return;
    }

    // 如果当前有消息显示，先隐藏
    _hideCurrent();

    // 显示新消息
    _showMessage(context, message, duration);
  }

  void _showMessage(BuildContext context, String message, Duration duration) {
    _currentMessage = message;

    final overlay = OverlayEntry(
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        return Positioned(
          // 向上移动一些，不紧贴底部
          bottom: screenSize.height * 0.15,
          left: screenSize.width * 0.1,
          right: screenSize.width * 0.1,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                // 气泡样式
                color:
                    Theme.of(context).snackBarTheme.backgroundColor ??
                    Colors.black87,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      Theme.of(context).snackBarTheme.contentTextStyle?.color ??
                      Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(overlay);
    _currentOverlay = overlay;

    // 设置自动隐藏定时器
    _currentTimer = Timer(duration, () {
      _hideCurrent();
    });
  }

  void _hideCurrent() {
    if (_currentTimer != null) {
      _currentTimer?.cancel();
      _currentTimer = null;
    }

    if (_currentOverlay != null) {
      _currentOverlay?.remove();
      _currentOverlay = null;
    }

    _currentMessage = null;
  }
}
