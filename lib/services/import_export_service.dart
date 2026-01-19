import 'dart:convert';
import 'package:csv/csv.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../services/storage_service.dart';

class ImportExportService {
  final StorageService _storageService = StorageService();

  // 导出为JSON格式
  Future<String> exportToJson() async {
    final accounts = await _storageService.getAccounts();
    final categories = await _storageService.getCategories();

    final exportData = {
      'version': '1.0.0',
      'exportDate': DateTime.now().toIso8601String(),
      'accounts': accounts.map((account) => account.toMap()).toList(),
      'categories': categories.map((category) => category.toMap()).toList(),
    };

    return json.encode(exportData);
  }

  // 导出为CSV格式
  Future<String> exportToCsv() async {
    final accounts = await _storageService.getAccounts();

    // CSV header
    final header = ['平台名称', '账号', '密码', '分类', '备注', '网址', '创建时间', '更新时间'];
    final csvData = [header];

    // Convert accounts to CSV rows
    for (var account in accounts) {
      final row = [
        account.platform,
        account.username,
        account.password,
        account.category,
        account.remark ?? '',
        account.url ?? '',
        account.createdAt.toIso8601String(),
        account.updatedAt.toIso8601String(),
      ];
      csvData.add(row);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  // 从JSON格式导入
  Future<int> importFromJson(String jsonData) async {
    try {
      final importData = json.decode(jsonData) as Map<String, dynamic>;

      // Import categories
      if (importData.containsKey('categories')) {
        final categoriesList = importData['categories'] as List;
        for (var categoryData in categoriesList) {
          final category = Category.fromMap(categoryData);
          await _storageService.saveCategory(category);
        }
      }

      // Import accounts
      if (importData.containsKey('accounts')) {
        final accountsList = importData['accounts'] as List;
        for (var accountData in accountsList) {
          final account = Account.fromMap(accountData);
          await _storageService.saveAccount(account);
        }
        return accountsList.length;
      }

      return 0;
    } catch (e) {
      throw Exception('JSON格式错误：$e');
    }
  }

  // 从CSV格式导入
  Future<int> importFromCsv(String csvData) async {
    try {
      final csvRows = const CsvToListConverter().convert(csvData);
      if (csvRows.isEmpty) return 0;

      // Skip header row
      final accountsList = csvRows.skip(1).toList();
      int importedCount = 0;

      for (var row in accountsList) {
        if (row.length < 4) continue; // Skip invalid rows

        try {
          final account = Account(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            platform: row[0]?.toString() ?? '',
            username: row[1]?.toString() ?? '',
            password: row[2]?.toString() ?? '',
            category: row[3]?.toString() ?? '未分类',
            remark: row.length > 4 ? row[4]?.toString() : null,
            url: row.length > 5 ? row[5]?.toString() : null,
            createdAt: row.length > 6
                ? DateTime.parse(row[6].toString())
                : DateTime.now(),
            updatedAt: row.length > 7
                ? DateTime.parse(row[7].toString())
                : DateTime.now(),
          );

          await _storageService.saveAccount(account);
          importedCount++;
        } catch (e) {
          // Skip invalid rows
          continue;
        }
      }

      return importedCount;
    } catch (e) {
      throw Exception('CSV格式错误：$e');
    }
  }

  // 生成导出文件名
  String generateExportFileName(String format) {
    final now = DateTime.now();
    final dateString =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return 'password_manager_$dateString.$format';
  }
}
