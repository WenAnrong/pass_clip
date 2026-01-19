import 'package:flutter/foundation.dart';

// 全局刷新通知器（监听账号变化）
class RefreshNotifier extends ChangeNotifier {
  static final RefreshNotifier instance = RefreshNotifier();

  // 发送刷新通知
  void notifyRefresh() {
    notifyListeners(); // 通知所有监听者
  }
}
