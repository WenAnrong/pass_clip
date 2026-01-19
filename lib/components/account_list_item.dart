import 'package:flutter/material.dart';
import '../models/account.dart';

class AccountListItem extends StatelessWidget {
  final Account account;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const AccountListItem({
    super.key,
    required this.account,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
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
      ),
    );
  }
}
