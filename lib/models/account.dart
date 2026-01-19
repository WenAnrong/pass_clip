import 'dart:convert';

class Account {
  String id;
  String platform;
  String username;
  String password;
  String category;
  String? remark;
  String? url;
  DateTime createdAt;
  DateTime updatedAt;

  Account({
    required this.id,
    required this.platform,
    required this.username,
    required this.password,
    this.category = '未分类',
    this.remark,
    this.url,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // 将对象转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'platform': platform,
      'username': username,
      'password': password,
      'category': category,
      'remark': remark,
      'url': url,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // 从Map创建对象
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      platform: map['platform'],
      username: map['username'],
      password: map['password'],
      category: map['category'],
      remark: map['remark'],
      url: map['url'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // 将对象转换为JSON字符串
  String toJson() => json.encode(toMap());

  // 从JSON字符串创建对象
  factory Account.fromJson(String source) =>
      Account.fromMap(json.decode(source));
}
