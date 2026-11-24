# 如何构建

本仓库只保存模块的**文本部分**，不包含 WebView APK 本体。

## 目录说明

```
module.prop                              模块描述（Magisk 读取）
META-INF/com/google/android/update-binary 安装入口脚本
META-INF/com/google/android/updater-script 内容仅 "#MAGISK"
system/product/app/webview/webview.apk   ← 这里放 WebView APK（本仓库不提供）
```

## 需要你自己下载的部分

`system/product/app/webview/webview.apk` **不在本仓库**，因为它是约 197 MB 的二进制文件，不适合放进 git。

请从下面下载：

- **仓库**：<https://github.com/JonaNorman/WebViewPackage>
- **Release 页**：<https://github.com/JonaNorman/WebViewPackage/releases/tag/android>
- **本模块使用的版本**：`134.0.6998.39_min26_arm64.apk`

要求：

| 项 | 值 |
|---|---|
| 包名 | 必须是 `com.android.webview`（不是 Google 版） |
| 架构 | `arm64`（坚果 R2 为 arm64-v8a） |
| minSdk | 26（本机为 30，满足） |

下载后校验（应为）：

```
da886ba4b6ccb9883b8f88d2c999c58e6b15363faa7008c40be4bc1459ca341a
```

## 其他版本

`android` tag 下还提供 113、124、128、134 等多个版本，各版本均有 arm32 / arm64 / x86 三种架构。想换版本时注意：

1. **必须是 `com.android.webview` 包名**——`com.google.android.webview` 装了也不会被系统使用，因为 ROM 白名单只认前者
2. **minSdk 不能高于你的系统 SDK**（坚果 R2 是 30）
3. 架构要匹配

## 打包成模块

```sh
# 在仓库根目录
mkdir -p system/product/app/webview
cp <你下载的>134.0.6998.39_min26_arm64.apk system/product/app/webview/webview.apk

zip -r webview_upgrade_134.zip \
    module.prop \
    META-INF/ \
    system/ \
    README.md
```

或用任意 zip 工具，**关键要求**：

- `module.prop` 必须在 **zip 根目录**，且是**文件**不是目录
- `META-INF/com/google/android/update-binary` 必须存在
- `system/` 必须在 zip 根目录下

## 校验成品

```sh
unzip -l webview_upgrade_134.zip
sha256sum webview_upgrade_134.zip
```

本仓库 Release 中的成品：

```
大小   : 97,394,847 字节 (92.9 MB)
SHA256 : e7e5b515e564f1d267d4af57e6a79237d5f2eb957ce779cb3e7f447a4ed599ad
```
