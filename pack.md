# 如何打包应用

## 说明

这里的版本号统一管理，在 `pubspec.yaml` 中修改 `version:` 字段即可。

`version: 1.0.0+2` 说明：

格式为「展示版本号 + 构建版本号」，用英文加号分隔；1.0.0 是给用户看的语义化版本（主版本。次版本。修订版），+ 后面的 2 是给机器 / 应用商店看的构建版本号（必须唯一且递增）。修改这一行，Flutter 会自动同步到 Android、iOS 等所有平台的对应版本配置，无需逐个修改。

安卓中，上面这个对应：
- versionCode=2
- versionName=1.0.0

## 统一打包命令

可在 distribute_options.yaml 统一配置所以平台的打包命令。

需要先安装的包
```shell
dart pub global activate fastforge
```

打包命令：
```shell
fastforge release --name mobile   # 移动端
fastforge release --name mac   # macos
fastforge release --name windows  # windows
fastforge release --name linux   # linux
```
这样设计是为了适配各个平台，桌面平台只能打包本平台的应用

用此打包命令前请确保flutter原本的打包命令可用才行。

为防止打包报错，可通过这样的命令进行清理

1. 清理Flutter构建缓存
```shell
flutter clean
flutter pub get
```

2. 删除Fastforge打包产物目录
```shell
rm -rf dist/
```

## 相关配置

### android 平台

要将 `my_app_key.jks` 和 `key.properties` 放到 `android/`目录下。

`key.properties` 的结构为：
```properties
storePassword=
keyPassword=
keyAlias=
storeFile=./my_app_key.jks
```
这样才能正常打包。

如果需要改包名，请使用下面命令
```shell
flutter pub run change_app_package_name:main cn.iamwar.pass_clip
```

### macos

打包前需要安装的包
```shell
npm install -g appdmg
```

如果要修改包名，请用xcode打开macos文件夹项目，然后修改：

1. 点击左侧 Runner
2. 点击右侧的 Signing & Capabilities
3. 然后在 Bundle Identifier 填写包名

如果要修改软件的显示名，请修改 `macos/Runner/Info.plist` 下的 `<key>CFBundleDisplayName</key>` 的名字，然后还要修改xcode打开后的general下的 `Display Name` 。

如果要修改版权信息：
1. 打开 macos/Runner.xcodeproj，选中左侧的 Runner 工程
2. 切换到 Project → Build Settings 标签页
3. 修改 `PRODUCT_COPYRIGHT` 字段 


### windows

打包前需要安装的包: [inno](https://jrsoftware.org/)

然后去这里下载简体中文的语言包（不下载的话打包时会报错）：[https://jrsoftware.org/files/istrans/](https://jrsoftware.org/files/istrans/)

将下载的简体中文包放入 inno 软件的目录下的 `Languages` 里就行。

### linux

打包前需要安装的包：这里以我的debian13为例子
```shell
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev  # 基础环境
sudo apt install libsecret-1-dev binutils lld llvm-19-dev libfuse2 locate  # 必须库
```

要安装 Appimage Builder，请运行：
```shell
wget -O appimagetool "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
chmod +x appimagetool
sudo mv appimagetool /usr/local/bin/
```
