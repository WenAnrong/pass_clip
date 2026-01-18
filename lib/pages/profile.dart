import 'package:flutter/material.dart';
import 'package:pass_clip/services/import_export_service.dart';
import 'package:pass_clip/services/auth_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
      ),
      body: ListView(
        children: [
          // 修改解锁密码
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ListTile(
              title: const Text('修改解锁密码'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // 跳转到密码修改页面
                Navigator.pushNamed(context, '/passwordSetup');
              },
            ),
          ),
          // 数据导出
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ListTile(
              title: const Text('数据导出'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) {
                    return const ExportPage();
                  },
                );
              },
            ),
          ),
          // 数据导入
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ListTile(
              title: const Text('数据导入'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) {
                    return const ImportPage();
                  },
                );
              },
            ),
          ),
          // 分类管理
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ListTile(
              title: const Text('分类管理'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(context, '/categoryManagement');
              },
            ),
          ),
          // 生物识别设置
          FutureBuilder<bool>(
            future: AuthService().isBiometricAvailable(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data == true) {
                return Card(
                  margin: const EdgeInsets.all(16.0),
                  child: ListTile(
                    title: const Text('生物识别设置'),
                    trailing: const Switch(value: true, onChanged: null),
                    onTap: () {
                      // 生物识别设置
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('生物识别设置'),
                            content: const Text('生物识别功能已启用'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('确定'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                );
              } else {
                return const SizedBox();
              }
            },
          ),
          // 关于我们
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ListTile(
              title: const Text('关于我们'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // 关于我们页面
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('关于我们'),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('版本号：1.0.0'),
                          SizedBox(height: 8.0),
                          Text('开发信息：本地账号密码管理工具'),
                          SizedBox(height: 8.0),
                          Text('隐私政策：本APP所有数据仅存储在本地设备，无任何网络传输，保障数据安全。'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('确定'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          // 退出登录
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ListTile(
              title: const Text('退出登录', style: TextStyle(color: Colors.red)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('退出登录'),
                      content: const Text('确认退出登录？'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () async {
                            // 执行退出登录
                            await AuthService().saveLoginStatus(false);
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: const Text('确认'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          // 清除所有数据
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ListTile(
              title: const Text('清除所有数据', style: TextStyle(color: Colors.red)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('清除所有数据'),
                      content: const Text('清除所有数据将删除所有账号密码及设置，不可恢复，是否确认？'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: 实现清除所有数据的功能
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('功能开发中')),
                            );
                            Navigator.pop(context);
                          },
                          child: const Text('确认'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 导出页面
class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  final ImportExportService _importExportService = ImportExportService();
  String _exportFormat = 'JSON';
  bool _isExporting = false;

  // 导出数据
  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      String exportData;
      String fileName;

      if (_exportFormat == 'JSON') {
        exportData = await _importExportService.exportToJson();
        fileName = _importExportService.generateExportFileName('json');
      } else {
        exportData = await _importExportService.exportToCsv();
        fileName = _importExportService.generateExportFileName('csv');
      }

      // 保存到本地文件
      final directory = await getExternalStorageDirectory();
      final path = '${directory?.path}/$fileName';
      final file = File(path);
      await file.writeAsString(exportData);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出成功：$path')),
      );
    } catch (e) {
      setState(() {
        _isExporting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '数据导出',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          const Text('选择导出格式：'),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Radio(
                value: 'JSON',
                groupValue: _exportFormat,
                onChanged: (value) {
                  setState(() {
                    _exportFormat = value!;
                  });
                },
              ),
              const Text('JSON格式'),
              const SizedBox(width: 16.0),
              Radio(
                value: 'CSV',
                groupValue: _exportFormat,
                onChanged: (value) {
                  setState(() {
                    _exportFormat = value!;
                  });
                },
              ),
              const Text('CSV格式'),
            ],
          ),
          const SizedBox(height: 24.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('取消'),
              ),
              const SizedBox(width: 16.0),
              ElevatedButton(
                onPressed: _isExporting ? null : _exportData,
                child: _isExporting
                    ? const SizedBox(
                        width: 20.0,
                        height: 20.0,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      )
                    : const Text('导出'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 导入页面
class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  final ImportExportService _importExportService = ImportExportService();
  bool _isImporting = false;
  String? _fileName;
  String? _fileContent;

  // 选择文件
  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();

        setState(() {
          _fileName = result.files.single.name;
          _fileContent = content;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择文件失败：$e')),
      );
    }
  }

  // 导入数据
  Future<void> _importData() async {
    if (_fileContent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择文件')),
      );
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      int importedCount;

      if (_fileName!.endsWith('.json')) {
        importedCount = await _importExportService.importFromJson(_fileContent!);
      } else if (_fileName!.endsWith('.csv')) {
        importedCount = await _importExportService.importFromCsv(_fileContent!);
      } else {
        throw Exception('不支持的文件格式');
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入成功，共导入$importedCount条账号信息')),
      );
    } catch (e) {
      setState(() {
        _isImporting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '数据导入',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          const Text('选择导入文件（支持JSON和CSV格式）：'),
          const SizedBox(height: 16.0),
          InkWell(
            onTap: _selectFile,
            child: Container(
              width: double.infinity,
              height: 150.0,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: _fileName != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(height: 8.0),
                          Text('已选择：$_fileName'),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file),
                          SizedBox(height: 8.0),
                          Text('点击选择文件'),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('取消'),
              ),
              const SizedBox(width: 16.0),
              ElevatedButton(
                onPressed: _isImporting ? null : _importData,
                child: _isImporting
                    ? const SizedBox(
                        width: 20.0,
                        height: 20.0,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      )
                    : const Text('导入'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
