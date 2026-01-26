import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class About extends StatelessWidget {
  const About({super.key});

  // 打开开源地址链接的方法
  Future<void> _openSourceUrl() async {
    const url = "https://github.com/WenAnrong/pass_clip";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw "无法打开链接: $url";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bottomTextColor = isDarkMode ? Colors.grey : Colors.grey[600];

    return Scaffold(
      appBar: AppBar(title: const Text("关于"), centerTitle: true),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Image.asset(
                      "lib/assets/icon/icon-512x512-linux.png",
                      width: 100,
                      height: 100,
                      alignment: Alignment.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("秘荚", style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 20),
                  Text(
                    "好用的账号密码管理器",
                    style: TextStyle(fontSize: 20, color: bottomTextColor),
                  ),
                ],
              ),
            ),
            // 底部信息：版本号 + 开源地址 + 版权
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                children: [
                  // 开源地址（可点击跳转）
                  InkWell(
                    onTap: _openSourceUrl,
                    child: Text(
                      "开源地址",
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode
                            ? Colors.blueAccent
                            : Colors.blue[400], // 链接用蓝色更醒目
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 版本号
                  Text(
                    "版本号：v1.0.0",
                    style: TextStyle(fontSize: 12, color: bottomTextColor),
                  ),
                  const SizedBox(height: 10),
                  // 版权信息
                  Text(
                    "Copyright © 2026 WenAnrong.All Rights Reserved.",
                    style: TextStyle(fontSize: 12, color: bottomTextColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
