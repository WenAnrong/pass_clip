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
      final client = http.Client();
      final request = http.Request('PROPFIND', Uri.parse(config.url));
      request.headers.addAll({
        'Authorization':
            'Basic ${base64Encode(utf8.encode('${config.username}:${config.password}'))}',
        'Depth': '0',
      });
      final response = await client.send(request);
      client.close();

      // 坚果云可能返回207 Multi-Status或其他WebDAV特定状态码，所以我们接受200-399之间的状态码
      final success = response.statusCode >= 200 && response.statusCode < 400;
      return success;
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

      // 构建基础URL - 确保URL格式正确
      final baseUrl = config.url.endsWith('/') ? config.url : '${config.url}/';
      final uploadUrl = Uri.parse('$baseUrl$fileName');

      // 1. 获取WebDAV目录中的所有文件
      final client = http.Client();
      final propfindRequest = http.Request('PROPFIND', Uri.parse(baseUrl));
      propfindRequest.headers.addAll({
        'Authorization':
            'Basic ${base64Encode(utf8.encode('${config.username}:${config.password}'))}',
        'Depth': '1',
      });
      final propfindResponse = await client.send(propfindRequest);
      final propfindResponseBody = await propfindResponse.stream
          .bytesToString();

      // 2. 解析XML响应，找出所有旧的导出文件
      final RegExp filePattern = RegExp(
        r'<d:displayname>(pass_clip_export_.*json)</d:displayname>',
        dotAll: true,
      );
      final matches = filePattern.allMatches(propfindResponseBody);
      final oldFiles = matches
          .map((match) => match.group(1))
          .whereType<String>()
          .toList();

      // 3. 删除所有旧文件
      for (final oldFile in oldFiles) {
        final deleteUrl = Uri.parse('$baseUrl$oldFile');
        final deleteRequest = http.Request('DELETE', deleteUrl);
        deleteRequest.headers.addAll({
          'Authorization':
              'Basic ${base64Encode(utf8.encode('${config.username}:${config.password}'))}',
        });
        await client.send(deleteRequest);
      }

      // 4. 上传新文件
      final putRequest = http.Request('PUT', uploadUrl);
      putRequest.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization':
            'Basic ${base64Encode(utf8.encode('${config.username}:${config.password}'))}',
      });
      putRequest.body = jsonData;
      final putResponse = await client.send(putRequest);
      client.close();

      // 坚果云可能返回不同的状态码，我们接受200-299之间的状态码
      if (putResponse.statusCode < 200 || putResponse.statusCode >= 300) {
        throw Exception(
          '上传失败：${putResponse.statusCode} ${putResponse.reasonPhrase}\nURL: $uploadUrl',
        );
      }
    } catch (e) {
      throw Exception('WebDAV上传失败：$e');
    }
  }

  // 从WebDAV下载JSON文件
  Future<int> downloadFromWebDAV(
    WebDAVConfig config, {
    bool overwrite = false,
  }) async {
    try {
      // 生成文件名
      final fileName = generateExportFileName('json');

      // 构建下载URL - 确保URL格式正确
      final baseUrl = config.url.endsWith('/') ? config.url : '${config.url}/';
      final downloadUrl = Uri.parse('$baseUrl$fileName');

      // 从WebDAV服务器下载
      final response = await http.get(
        downloadUrl,
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('${config.username}:${config.password}'))}',
          'Depth': '0',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          '下载失败：${response.statusCode} ${response.reasonPhrase}\nURL: $downloadUrl',
        );
      }

      // 确保正确解码为UTF-8，解决乱码问题
      final jsonData = utf8.decode(response.bodyBytes);

      // 导入数据
      return await importFromJson(jsonData, overwrite: overwrite);
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

    // 收集所有自定义字段键
    final customFieldKeys = <String>{};
    for (var account in accounts) {
      customFieldKeys.addAll(account.customFields.keys);
    }

    // 排序自定义字段键，确保顺序一致
    final sortedCustomFieldKeys = customFieldKeys.toList()..sort();

    // CSV header
    final header = ['平台名称', '账号', '密码', '分类', '备注', '网址', '创建时间', '更新时间'];
    // 添加自定义字段到表头
    header.addAll(sortedCustomFieldKeys);
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
      // 添加自定义字段值
      for (var key in sortedCustomFieldKeys) {
        row.add(account.customFields[key] ?? '');
      }
      csvData.add(row);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  // 从JSON格式导入
  Future<int> importFromJson(String jsonData, {bool overwrite = false}) async {
    try {
      final importData = json.decode(jsonData) as Map<String, dynamic>;

      // 如果是覆盖模式，先清空现有数据
      if (overwrite) {
        // 清空账号数据
        await _storageService.saveAccounts([]);
        // 清空分类数据，但保留默认分类
        await _storageService.saveCategories([]);
      }

      // Import categories
      if (importData.containsKey('categories')) {
        final categoriesList = importData['categories'] as List;
        for (var categoryData in categoriesList) {
          final category = Category.fromMap(categoryData);
          await _storageService.saveCategory(category);
        }
      }

      // Import accounts
      int importedCount = 0;
      if (importData.containsKey('accounts')) {
        final accountsList = importData['accounts'] as List;
        for (var accountData in accountsList) {
          final account = Account.fromMap(accountData);
          await _storageService.saveAccount(account);
          importedCount++;
        }
      }

      return importedCount;
    } catch (e) {
      throw Exception('JSON格式错误：$e');
    }
  }

  // 生成导出文件名
  String generateExportFileName(String format) {
    final now = DateTime.now();
    final dateString =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return 'pass_clip_$dateString.$format';
  }
}
