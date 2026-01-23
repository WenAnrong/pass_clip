import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pass_clip/models/account.dart';

class AccountListItem extends StatelessWidget {
  final Account account;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const AccountListItem({
    super.key,
    required this.account,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // 检测是否为桌面平台
    final bool isDesktop =
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows;

    // 提取列表项核心内容（复用代码，避免冗余）
    Widget buildItemContent() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.platform,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(account.username),
                const SizedBox(height: 2),
                Text(account.updatedAt.toString().substring(0, 10)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(account.category),
            ),
          ],
        ),
      );
    }

    // 桌面平台使用右键菜单
    if (isDesktop) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          onSecondaryTapDown: (details) {
            _showContextMenu(context, details.globalPosition);
          },
          // 关键修复1：添加透明背景，确保整个区域可点击
          child: Container(
            width: double.infinity, // 铺满父容器宽度
            decoration: const BoxDecoration(color: Colors.transparent),
            child: buildItemContent(),
          ),
        ),
      );
    }
    // 移动平台保持长按删除
    else {
      return InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        // 给InkWell添加水波纹效果的同时，确保点击区域完整
        child: buildItemContent(),
      );
    }
  }

  // 显示右键菜单（修复回调执行时机问题）
  void _showContextMenu(BuildContext context, Offset tapPosition) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromLTWH(tapPosition.dx, tapPosition.dy, 0, 0),
      Offset.zero & overlay.size,
    );

    // 关键修复2：使用showMenu的onSelected替代PopupMenuItem的onTap
    showMenu(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          value: 'delete',
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: const [
                Icon(Icons.delete, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('删除'),
              ],
            ),
          ),
        ),
      ],
    ).then((value) {
      // 菜单关闭后执行回调，避免上下文失效
      if (value == 'delete') {
        onDelete();
      }
    });
  }
}
