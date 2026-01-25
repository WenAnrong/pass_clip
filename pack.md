# 如何打包应用

## 说明

这里的版本号统一管理，在 `pubspec.yaml` 中修改 `version:` 字段即可。

`version: 1.0.0+2` 说明：

格式为「展示版本号 + 构建版本号」，用英文加号分隔；1.0.0 是给用户看的语义化版本（主版本。次版本。修订版），+ 后面的 2 是给机器 / 应用商店看的构建版本号（必须唯一且递增）。修改这一行，Flutter 会自动同步到 Android、iOS 等所有平台的对应版本配置，无需逐个修改。

安卓中，上面这个对应：
- versionCode=2
- versionName=1.0.0

## 统一打包命令和配置

可在 distribute_options.yaml 统一配置所以平台的打包命令。

需要先安装的包
```shell
dart pub global activate fastforge  # 打包专用
npm install -g appdmg               # mac打包成dmg专用
```

打包命令：
```shell
fastforge release --name pack
```
用此打包命令前请确保flutter原本的打包命令可用才行。

为防止打包报错，可通过这样的命令进行清理

1. 清理Flutter构建缓存
```shell
flutter clean && flutter pub get
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

如果要修改包名，请用xcode打开macos文件夹项目，然后修改：

1. 点击左侧 Runner
2. 点击右侧的 Signing & Capabilities
3. 然后在 Bundle Identifier 填写包名

如果要修改软件的显示名，请修改 `macos/Runner/Info.plist` 下的 `<key>CFBundleDisplayName</key>` 的名字，然后还要修改xcode打开后的general下的 `Display Name` 。

如果要修改版权信息：
1. 打开 macos/Runner.xcodeproj，选中左侧的 Runner 工程
2. 切换到 Project → Build Settings 标签页
3. 修改 `PRODUCT_COPYRIGHT` 字段 