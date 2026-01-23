# 如何打包应用

## 说明

这里的版本号统一管理，在 `pubspec.yaml` 中修改 `version:` 字段即可。

`version: 1.0.0+2` 说明：

格式为「展示版本号 + 构建版本号」，用英文加号分隔；1.0.0 是给用户看的语义化版本（主版本。次版本。修订版），+ 后面的 2 是给机器 / 应用商店看的构建版本号（必须唯一且递增）。修改这一行，Flutter 会自动同步到 Android、iOS 等所有平台的对应版本配置，无需逐个修改。

安卓中，上面这个对应：
- versionCode=2
- versionName=1.0.0

## android 平台

### 基本步骤

要将 `my_app_key.jks` 和 `key.properties` 放到 `android/`目录下。

`key.properties` 的结构为：
```properties
storePassword=
keyPassword=
keyAlias=
storeFile=./my_app_key.jks
```
然后执行
```bash
flutter build apk --release
```
即可打包完成。

### 说明

本项目打包安卓只会打包成arm64的，其他的如果想打包请去 `android/app/build.gradle.kts` 修改 `ndk.abiFilters.addAll(listOf("arm64-v8a"))` 这个部分