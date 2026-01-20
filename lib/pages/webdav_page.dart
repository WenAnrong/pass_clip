import 'package:flutter/material.dart';
import 'package:pass_clip/services/import_export_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class WebDAVPage extends StatefulWidget {
  const WebDAVPage({super.key});

  @override
  State<WebDAVPage> createState() => _WebDAVPageState();
}

class _WebDAVPageState extends State<WebDAVPage> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final ImportExportService _importExportService = ImportExportService();
  bool _isLoading = false;
  bool _isTesting = false;
  bool _isUploading = false;
  bool _isDownloading = false;
  // 下载模式：true表示覆盖本地数据，false表示合并到本地
  bool _overwriteMode = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 加载已保存的WebDAV配置
  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final config = await _importExportService.getWebDAVConfig();
      if (config != null) {
        _urlController.text = config.url;
        _usernameController.text = config.username;
        _passwordController.text = config.password;
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '加载配置失败：$e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 保存WebDAV配置
  Future<void> _saveConfig() async {
    if (_formKey.currentState!.validate()) {
      final url = _urlController.text;
      final username = _usernameController.text;
      final password = _passwordController.text;

      setState(() {
        _isLoading = true;
      });

      try {
        final config = WebDAVConfig(
          url: url,
          username: username,
          password: password,
        );

        await _importExportService.saveWebDAVConfig(config);

        Fluttertoast.showToast(msg: 'WebDAV配置保存成功');
      } catch (e) {
        Fluttertoast.showToast(msg: '保存配置失败：$e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 测试WebDAV连接
  Future<void> _testConnection() async {
    if (_formKey.currentState!.validate()) {
      final url = _urlController.text;
      final username = _usernameController.text;
      final password = _passwordController.text;

      setState(() {
        _isTesting = true;
      });

      try {
        final config = WebDAVConfig(
          url: url,
          username: username,
          password: password,
        );

        final isConnected = await _importExportService.testWebDAVConnection(
          config,
        );
        if (isConnected) {
          Fluttertoast.showToast(msg: 'WebDAV连接测试成功');
        } else {
          Fluttertoast.showToast(msg: 'WebDAV连接测试失败');
        }
      } catch (e) {
        Fluttertoast.showToast(msg: '测试连接失败：$e');
      } finally {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  // 上传数据到WebDAV
  Future<void> _uploadData() async {
    final config = await _importExportService.getWebDAVConfig();
    if (config == null) {
      Fluttertoast.showToast(msg: '请先配置WebDAV');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      await _importExportService.uploadToWebDAV(config);
      Fluttertoast.showToast(msg: '数据上传成功');
    } catch (e) {
      Fluttertoast.showToast(msg: '上传失败：$e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // 从WebDAV下载数据
  Future<void> _downloadData() async {
    final config = await _importExportService.getWebDAVConfig();
    if (config == null) {
      Fluttertoast.showToast(msg: '请先配置WebDAV');

      return;
    }

    // 弹出下载模式选择对话框
    if (!mounted) return;
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('选择下载模式'),
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
              child: Text('将下载的数据合并到本地，不影响现有数据'),
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
              child: Text('清空本地所有数据，使用下载的数据完全替换'),
            ),
          ],
        );
      },
    );

    // 如果用户取消了选择，则不进行下载
    if (result == null) {
      return;
    }

    setState(() {
      _isDownloading = true;
      _overwriteMode = result;
    });

    try {
      final importedCount = await _importExportService.downloadFromWebDAV(
        config,
        overwrite: _overwriteMode,
      );

      final modeText = _overwriteMode ? '覆盖' : '合并';
      Fluttertoast.showToast(
        msg: '数据下载成功，已$modeText本地数据，共导入$importedCount条账号信息',
      );
    } catch (e) {
      Fluttertoast.showToast(msg: '下载失败：$e');
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebDAV配置')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16.0),
                        const Text(
                          'WebDAV服务器配置',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        TextFormField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                            labelText: '服务器地址',
                            hintText: '例如: https://example.com/webdav/',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入服务器地址';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: '用户名',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入用户名';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: '密码',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入密码';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveConfig,
                                child: const Text('保存配置'),
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isTesting ? null : _testConnection,
                                child: _isTesting
                                    ? const SizedBox(
                                        width: 20.0,
                                        height: 20.0,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                        ),
                                      )
                                    : const Text('测试连接'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32.0),
                        const Divider(),
                        const SizedBox(height: 16.0),
                        const Text(
                          '数据同步',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isUploading ? null : _uploadData,
                                icon: _isUploading
                                    ? const SizedBox(
                                        width: 20.0,
                                        height: 20.0,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                        ),
                                      )
                                    : const Icon(Icons.upload),
                                label: const Text('上传到WebDAV'),
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isDownloading
                                    ? null
                                    : _downloadData,
                                icon: _isDownloading
                                    ? const SizedBox(
                                        width: 20.0,
                                        height: 20.0,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                        ),
                                      )
                                    : const Icon(Icons.download),
                                label: const Text('从WebDAV下载'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        const Text('上传说明：将当前所有账号数据以JSON格式上传到WebDAV服务器。'),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
