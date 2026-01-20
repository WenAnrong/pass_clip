import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pass_clip/models/account.dart';
import 'package:pass_clip/models/category.dart';
import 'package:pass_clip/services/storage_service.dart';

// WebDAV配置模型
class WebDAVConfig {
  final String url;
  final String username;
  final String password;

  WebDAVConfig({
    required this.url,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {'url': url, 'username': username, 'password': password};
  }

  factory WebDAVConfig.fromMap(Map<String, dynamic> map) {
    return WebDAVConfig(
      url: map['url'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
    );
  }
}

class ImportExportService {
  final StorageService _storageService = StorageService();
  static const String _webdavConfigKey = 'webdav_config';

  // 获取SharedPreferences实例
  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // 保存WebDAV配置
  Future<void> saveWebDAVConfig(WebDAVConfig config) async {
    final prefs = await _getPrefs();
    await prefs.setString(_webdavConfigKey, json.encode(config.toMap()));
  }

  // 获取WebDAV配置
  Future<WebDAVConfig?> getWebDAVConfig() async {
    final prefs = await _getPrefs();
    final configJson = prefs.getString(_webdavConfigKey);
    if (configJson == null) return null;
    final configMap = json.decode(configJson) as Map<String, dynamic>;
    return WebDAVConfig.fromMap(configMap);
  }

  // 测试WebDAV连接
  Future<bool> testWebDAVConnection(WebDAVConfig config) async {
    try {
      final response = await http.get(
        Uri.parse(config.url),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('${config.username}:${config.password}'))}',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 上传JSON文件到WebDAV
  Future<void> uploadToWebDAV(WebDAVConfig config) async {
    try {
      // 导出JSON数据
      final jsonData = await exportToJson();

      // 生成文件名
      final fileName = generateExportFileName('json');

      // 上传到WebDAV服务器
      final response = await http.put(
        Uri.parse(
          '${config.url.endsWith('/') ? config.url : '${config.url}/'}$fileName',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Basic ${base64Encode(utf8.encode('${config.username}:${config.password}'))}',
        },
        body: jsonData,
      );

      if (response.statusCode != 201 && response.statusCode != 204) {
        throw Exception('上传失败：${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('WebDAV上传失败：$e');
    }
  }

  // 从WebDAV下载JSON文件
  Future<int> downloadFromWebDAV(WebDAVConfig config) async {
    try {
      // 生成文件名
      final fileName = generateExportFileName('json');

      // 从WebDAV服务器下载
      final response = await http.get(
        Uri.parse(
          '${config.url.endsWith('/') ? config.url : '${config.url}/'}$fileName',
        ),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('${config.username}:${config.password}'))}',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('下载失败：${response.statusCode} ${response.reasonPhrase}');
      }

      // 导入数据
      return await importFromJson(response.body);
    } catch (e) {
      throw Exception('WebDAV下载失败：$e');
    }
  }

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
