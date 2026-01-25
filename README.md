# passClip（秘荚）

一个安全、高效的密码管理工具，用于存储和管理账号密码，支持多平台使用。

![passClip](README_IMAGES/image1.png)

## 功能特性

- **安全存储**：本地加密存储账号密码，保护您的敏感信息
- **多平台支持**：支持 Windows、macOS、Linux 和移动设备
- **数据导入导出**：支持 JSON 和 CSV 格式的数据导入导出
- **WebDAV备份**：备份数据到 WebDAV 服务器
- **多平台同步**：支持在不同平台之间通过webdav同步数据
- **分享功能**：移动端支持分享导出的数据文件

## 快速开始

### 环境要求

- Flutter 3.38+
- Dart 3.10+ 
- 各平台对应开发工具（如 Android Studio、Xcode 等）

### 安装与运行

1. **克隆项目**
   ```shell
   git clone https://github.com/WenAnrong/pass_clip.git
   cd pass_clip
   ```

2. **安装依赖**
   ```shell
   flutter pub get
   ```

3. **运行应用**
   - Android：`flutter run -d android`
   - iOS：`flutter run -d ios`
   - 桌面：`flutter run -d macos` 或 `flutter run -d windows` 或 `flutter run -d linux`

   本项目默认禁止在 Web 平台运行，因为 Web 平台不支持本地文件存储。

## 技术架构

### 依赖库

- `flutter`：核心框架
- `flutter_secure_storage`：安全存储敏感数据
- `encrypt`：AES加密解密
- `csv`：CSV文件读写
- `shared_preferences`：普通配置存储
- `path_provider`：文件路径获取
- `share_plus`：分享文件
- `http`：HTTP客户端
- `webdav_client`：WebDAV客户端
- `window_manager`：桌面端窗口管理
- `file_selector`：全平台文件选择器
- `url_launcher`：打开文件/文件夹

## 生成图标和修改包名

### 依赖
这里使用
- `flutter_launcher_icons`：应用图标生成
- `change_app_package_name`：应用包名修改

两个插件进行修改

### 修改包名

这个插件可以帮助我们快速修改包名（ios和android的），命令如下
```shell
flutter pub run change_app_package_name:main cn.iamwar.pass_clip
```

### 修改图标

在项目根目录下执行以下命令，即可生成应用图标：
配置文件在 `pubspec.yaml` 中，修改 `flutter_launcher_icons` 部分即可。

要更换应用图标可更换 `lib/assets/icons/` 目录下的图标文件。
```shell
flutter pub run flutter_launcher_icons:main
```

## 打包

请看[pack.md](pack.md)

## 项目结构

```
pass_clip/
├── lib/
│   ├── assets/          # 静态资源
│   ├── models/          # 数据模型
│   ├── pages/           # 页面文件
│   ├── routes/          # 路由配置
│   ├── services/        # 服务层
│   ├── theme/           # 主题配置
│   ├── utils/           # 工具类
│   └── main.dart        # 应用入口
├── android/             # Android 项目目录
├── ios/                 # iOS 项目目录
├── linux/               # Linux 项目目录
├── macos/               # macOS 项目目录
├── web/                 # Web 项目目录
├── windows/             # Windows 项目目录
├── distribute_options.yaml  # 打包配置
├── LICENSE              # 开源协议
├── README_IMAGES/       # 文档图片
├── pubspec.yaml         # 依赖配置
└── README.md            # 项目说明
```

## 注意事项

- 导出的数据为明文，请妥善保管
- CSV 格式仅支持导出，不支持导入
- 导入数据时请确保文件格式正确，避免数据丢失

## 贡献

欢迎提交 Issue 和 Pull Request 来帮助改进这个项目。

## 许可证

本项目基础版采用 BSD 3-Clause 开源协议，核心规则：

✅ 允许自由使用、修改、分发

⚠️ 约束条件：
- 分发时需保留原版权声明与协议文本
- 禁止用「pass_clip」或作者名做推广背书（需书面授权）

完整协议文本请见项目根目录的 [LICENSE](LICENSE) 文件。

