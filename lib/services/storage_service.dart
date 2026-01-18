import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/category.dart';
import 'dart:convert';

class StorageService {
  static const String _accountsKey = 'accounts';
  static const String _categoriesKey = 'categories';

  // 获取SharedPreferences实例
  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // 账号相关操作

  // 保存账号列表
  Future<void> saveAccounts(List<Account> accounts) async {
    final prefs = await _getPrefs();
    final accountsJson = accounts.map((account) => account.toJson()).toList();
    await prefs.setString(_accountsKey, json.encode(accountsJson));
  }

  // 获取账号列表
  Future<List<Account>> getAccounts() async {
    final prefs = await _getPrefs();
    final accountsJson = prefs.getString(_accountsKey);
    if (accountsJson == null) return [];
    final accountsList = json.decode(accountsJson) as List;
    return accountsList.map((account) => Account.fromJson(account)).toList();
  }

  // 保存单个账号
  Future<void> saveAccount(Account account) async {
    final accounts = await getAccounts();
    final index = accounts.indexWhere((a) => a.id == account.id);
    if (index != -1) {
      accounts[index] = account;
    } else {
      accounts.add(account);
    }
    await saveAccounts(accounts);
  }

  // 删除账号
  Future<void> deleteAccount(String id) async {
    final accounts = await getAccounts();
    accounts.removeWhere((account) => account.id == id);
    await saveAccounts(accounts);
  }

  // 分类相关操作

  // 保存分类列表
  Future<void> saveCategories(List<Category> categories) async {
    final prefs = await _getPrefs();
    final categoriesJson = categories.map((category) => category.toJson()).toList();
    await prefs.setString(_categoriesKey, json.encode(categoriesJson));
  }

  // 获取分类列表
  Future<List<Category>> getCategories() async {
    final prefs = await _getPrefs();
    final categoriesJson = prefs.getString(_categoriesKey);
    if (categoriesJson == null) {
      // 默认分类
      final defaultCategories = [
        Category(name: '未分类'),
        Category(name: '社交'),
        Category(name: '办公'),
        Category(name: '金融'),
        Category(name: '其他'),
      ];
      await saveCategories(defaultCategories);
      return defaultCategories;
    }
    final categoriesList = json.decode(categoriesJson) as List;
    return categoriesList.map((category) => Category.fromJson(category)).toList();
  }

  // 保存单个分类
  Future<void> saveCategory(Category category) async {
    final categories = await getCategories();
    final index = categories.indexWhere((c) => c.name == category.name);
    if (index != -1) {
      categories[index] = category;
    } else {
      categories.add(category);
    }
    await saveCategories(categories);
  }

  // 删除分类
  Future<void> deleteCategory(String categoryName) async {
    final categories = await getCategories();
    categories.removeWhere((category) => category.name == categoryName);
    await saveCategories(categories);
    
    // 将该分类下的账号移至未分类
    final accounts = await getAccounts();
    for (var account in accounts) {
      if (account.category == categoryName) {
        account.category = '未分类';
        account.updatedAt = DateTime.now();
      }
    }
    await saveAccounts(accounts);
  }

  // 更新分类下的账号数量
  Future<void> updateCategoryCount(String categoryName) async {
    final accounts = await getAccounts();
    final count = accounts.where((account) => account.category == categoryName).length;
    
    final categories = await getCategories();
    final index = categories.indexWhere((category) => category.name == categoryName);
    if (index != -1) {
      categories[index].count = count;
      await saveCategories(categories);
    }
  }
}
