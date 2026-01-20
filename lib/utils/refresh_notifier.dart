import 'dart:async';

import 'package:flutter/foundation.dart';

// 全局刷新通知器（监听账号变化）
class RefreshNotifier extends ChangeNotifier {
  // 1. 私有构造函数，确保单例不被意外实例化
  RefreshNotifier._internal();

  // 2. 规范的单例实现
  static final RefreshNotifier instance = RefreshNotifier._internal();

  // 防抖定时器，避免高频通知
  Timer? _debounceTimer;

  // 带防抖的刷新通知
  void notifyRefresh({Duration debounce = const Duration(milliseconds: 300)}) {
    // 取消之前的定时器
    _debounceTimer?.cancel();
    // 延迟发送通知，避免高频触发
    _debounceTimer = Timer(debounce, () {
      notifyListeners();
    });
  }

  // 销毁时取消定时器（虽然单例很少销毁，但兜底）
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
