import 'dart:convert';

class Category {
  String name;
  int count;

  Category({
    required this.name,
    this.count = 0,
  });

  // 将对象转换为Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'count': count,
    };
  }

  // 从Map创建对象
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      name: map['name'],
      count: map['count'],
    );
  }

  // 将对象转换为JSON字符串
  String toJson() => json.encode(toMap());

  // 从JSON字符串创建对象
  factory Category.fromJson(String source) => Category.fromMap(json.decode(source));
}
