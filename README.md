# Smartisan R2 WebView 替换（75 → 134）

坚果 R2（`darwin` / DT2002C，Android 11 / API 30）系统 WebView 升级 Magisk 模块。

把系统 WebView 从 **75.0.3770.156** 替换为 **134.0.6998.39**（AOSP 官方预编译件，arm64）。

---


> **注意：本仓库不包含 WebView APK 本体。**
>
> 约 197 MB 的 `webview.apk` 是二进制文件，不适合放进 git。仓库里只有模块的**文本部分**（`module.prop`、`update-binary`、`updater-script`）。
>
> - 需要 APK 请去 [JonaNorman/WebViewPackage](https://github.com/JonaNorman/WebViewPackage/releases/tag/android) 下载 `134.0.6998.39_min26_arm64.apk`
> - 想要**其他版本**（113 / 124 / 128 / 134 等，各有 arm32 / arm64 / x86）也在同一个 Release 页
> - 选版本注意：包名必须是 `com.android.webview`，架构要 arm64，minSdk 不能高于你的系统 SDK
> - 打包方法见 [BUILD.md](BUILD.md)
>
> 不想自己打包的，直接下 [Releases](../../releases) 里的成品。

---

## 为什么需要这个

坚果 R2 的 Smartisan OS 把 WebView provider 白名单锁死在 `com.android.webview` 一个包上：

- `framework-res.apk` 的 `res/xml/config_webview_packages.xml` 只声明了这一项
- `dumpsys webviewupdate` 因此只认它一个 valid provider
- 开发者选项里没有「WebView 实现」切换入口
- 机器上即使装着 `com.google.android.webview`（新版）也不会被使用

结果是 WebView 停留在 75（Chromium 75，2019 年），很多现代网页/应用跑不起来。典型症状：

- 依赖 `??=`（逻辑空赋值，Chrome 85+）的脚本直接 `SyntaxError`
- 页面永远不发 ready 事件，只能超时

## 为什么这样替换能生效

**不换 provider 身份，只换同一个位置上的文件。**

| 环节 | 做法 | 结果 |
|---|---|---|
| 包名 | 用 `com.android.webview`，不是 Google 版 | 撞上白名单唯一那条，直接通过 |
| 版本号 | 75 → 134 | WebViewUpdateService 自然选高版本 |
| 位置 | systemless 覆盖 `/product/app/webview/webview.apk` | 仍是系统应用本体，不需安装会话 |

因为包名和位置都没变，ROM 的白名单机制完全不需要改动，也**不需要改系统分区**。

## 实测结果（本机已验证）

```
$ su
# dumpsys webviewupdate
Current WebView package (name, version): (com.android.webview, 134.0.6998.39)
Preferred WebView package (name, version): (com.android.webview, 134.0.6998.39)
Valid package com.android.webview (versionName: 134.0.6998.39, versionCode: 699803901, targetSdkVersion: 35) is installed/enabled for all users
```

替换后：
- 依赖新内核的页面可以正常打开

> 注：系统「设置 → 应用管理」里可能仍显示 75，那是 Smartisan 设置应用的缓存未刷新，以 `dumpsys webviewupdate` 为准。

## 环境要求

- 坚果 R2（`ro.product.device` = `darwin`）
- Android 11 / API 30
- **Magisk**（本模块为 systemless 挂载，需要 root）
- 架构 arm64

## 安装

1. 备份 boot（Magisk 内备份，或 TWRP 导出）
2. 确认 Magisk 安全模式可用（开机时按住音量下键可禁用所有模块）
3. Magisk → 模块 → 从本地安装 → 选择 `webview_upgrade_134.zip`
4. 重启

## 验证

```sh
su -c dumpsys webviewupdate
```

第一行应显示 `com.android.webview, 134.0.6998.39`。

## 回滚

- Magisk 里禁用或删除 `webview_upgrade` 模块 → 重启
- 或开机时按住音量下键进安全模式，禁用全部模块

系统分区的原始文件从未被修改，回滚是干净的。

## 已知副作用

1. **首次启动变慢**：`/product/app/webview/oat/` 里是 75 版的预编译产物，与新内核不匹配，系统会重新编译。所有用到 WebView 的应用首次启动会慢一次，属正常现象。
2. **系统自带浏览器搜索可能闪退**：`com.android.browser` 在 134 上搜索功能异常（社区反馈）。不影响其他应用，也不影响 Google Chrome。
3. **OTA 后需重新确认**：系统更新会覆盖挂载。不过 Smartisan OS 已停止维护，实际影响很小。

## 文件校验

```
文件名 : webview_upgrade_134.zip
大小   : 97,394,847 字节 (92.9 MB)
SHA256 : e7e5b515e564f1d267d4af57e6a79237d5f2eb957ce779cb3e7f447a4ed599ad
```

内嵌 `webview.apk`：

```
SHA256 : da886ba4b6ccb9883b8f88d2c999c58e6b15363faa7008c40be4bc1459ca341a
签名   : AOSP testkey
        32:A2:FC:74:D7:31:10:58:59:E5:A8:5D:F1:6D:95:F1:02:D8:5B:22:09:9B:80:64:C5:D8:91:5C:61:DA:D1:E0
```

模块结构：

```
module.prop
META-INF/com/google/android/update-binary
META-INF/com/google/android/updater-script
system/product/app/webview/webview.apk
README.txt
```

## 关于签名

系统原版 75 由锤子官方密钥签名（`O=Smartisan`），本包内 APK 是 **AOSP 测试密钥**签名，两者不同。

因此**不能通过普通安装覆盖**（会报 `INSTALL_FAILED_UPDATE_INCOMPATIBLE`），只能通过 Magisk systemless 挂载。

## 来源与致谢

- WebView APK 来自 [JonaNorman/WebViewPackage](https://github.com/JonaNorman/WebViewPackage)（tag `android`），为 AOSP 官方预编译件，本仓库未对其做任何修改。
- 模块外壳（`module.prop`、`update-binary`、目录布局）为坚果 R2 适配。
- 方案参考了酷安社区坚果 R1 / R2 用户的实际替换经验。

## 免责声明

刷机有风险。首次操作前请务必备份 boot 并确认安全模式可用。作者不对设备损坏或数据丢失负责。

本模块只做一件事：把一个文件挂载到指定路径。它不修改系统分区、不写用户数据、不改白名单。
