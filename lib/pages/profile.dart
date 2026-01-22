import 'package:flutter/material.dart';
import 'package:pass_clip/services/import_export_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:pass_clip/utils/snackbar_util.dart';
import 'package:share_plus/share_plus.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的'), centerTitle: true),
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
          // WebDAV同步
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ListTile(
              title: const Text('WebDAV同步'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(context, '/webdav');
              },
            ),
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
                          Text('开发信息：war'),
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
    final navigator = Navigator.of(context);
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
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$fileName';
      final file = File(path);
      await file.writeAsString(exportData);

      navigator.pop();

      await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], text: '分享导出的账号数据'),
      );
    } catch (e) {
      setState(() {
        _isExporting = false;
      });
      // 显示失败提示
      if (mounted) {
        SnackBarUtil.show(context, '导出失败：$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '数据导出',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            const Text('选择导出格式：'),
            const SizedBox(height: 8.0),
            SegmentedButton<String>(
              selected: {_exportFormat},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _exportFormat = newSelection.first;
                });
              },
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(value: 'JSON', label: Text('JSON格式')),
                ButtonSegment<String>(value: 'CSV', label: Text('CSV格式')),
              ],
            ),
            const SizedBox(height: 12.0),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('提示：'),
                  SizedBox(height: 4.0),
                  Text("• 导出的数据是明文的，请保存好"),
                  Text('• csv格式可用wps等软件方便查看和编辑'),
                  Text('• 如果要在新的设备上导入，需要先导出到json格式，csv格式不支持导入'),
                ],
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
  // 下载模式：true表示覆盖本地数据，false表示合并到本地
  bool _overwriteMode = false;

  // 选择文件
  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
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
      // 显示失败提示
      if (mounted) {
        SnackBarUtil.show(context, '选择文件失败：$e');
      }
    }
  }

  // 导入数据
  Future<void> _importData() async {
    final navigator = Navigator.of(context);

    if (_fileContent == null) {
      // 显示提示
      if (mounted) {
        SnackBarUtil.show(context, '请先选择文件');
      }

      return;
    }

    // 弹出下载模式选择对话框
    if (!mounted) return;
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('选择导入模式'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, false); // 合并模式
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('合并到本地', style: TextStyle(fontSize: 16.0)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '将导入的数据合并到本地，不影响现有数据',
                style: TextStyle(fontSize: 12.0),
              ),
            ),

            const SizedBox(height: 16.0),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, true); // 覆盖模式
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('覆盖本地数据', style: TextStyle(fontSize: 16.0)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '清空本地所有数据，使用导入的数据完全替换',
                style: TextStyle(fontSize: 12.0),
              ),
            ),
          ],
        );
      },
    );

    // 如果用户取消了选择，则不进行导入
    if (result == null) {
      return;
    }

    setState(() {
      _isImporting = true;
      _overwriteMode = result;
    });

    try {
      int importedCount;

      if (_fileName!.endsWith('.json')) {
        importedCount = await _importExportService.importFromJson(
          _fileContent!,
          overwrite: _overwriteMode,
        );
      } else {
        throw Exception('只支持JSON格式的导入');
      }

      // 导入成功，返回上一页
      navigator.pop();
      // 显示成功提示
      final modeText = _overwriteMode ? '覆盖' : '合并';
      if (mounted) {
        SnackBarUtil.show(
          context,
          '导入成功，已$modeText本地数据，共导入$importedCount条账号信息',
        );
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
      });
      // 显示失败提示
      if (mounted) {
        SnackBarUtil.show(context, '导入失败：$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '数据导入',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            const Text('选择导入文件（只支持JSON格式）：'),
            const SizedBox(height: 16.0),
            InkWell(
              onTap: _selectFile,
              child: Container(
                width: double.infinity,
                height: 150.0,
                decoration: BoxDecoration(
                  border: Border.all(),
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
      ),
    );
  }
}
