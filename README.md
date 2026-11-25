# Smartisan R2 WebView 替换升级模块（75 → 134）

坚果 R2（`darwin` / DT2002C，Android 11 / API 30）系统 WebView 升级 Magisk 模块（**v1.1**）。

将系统 WebView 从出厂 **75.0.3770.156** 升级为 **134.0.6998.39**（AOSP 官方预编译件，`arm64`），并针对 **Magisk 排除列表（DenyList）/ Shamiko 隐藏 Root 场景下的白屏问题** 与 **卸载回滚缓存撕裂问题** 做了完整适配。

---

> **注意：本 Git 仓库仅保存模块的脚本与说明文件，不包含约 197 MB 的 WebView APK 本体。**
>
> - 直接刷机请前往 [**Releases**](../../releases) 下载打包好的成品压缩包 `webview_upgrade_134_v1.1.zip`。
> - 如需自行打包或更换其他版本（如 113 / 124 / 128 / 134），请前往 [JonaNorman/WebViewPackage (`android` tag)](https://github.com/JonaNorman/WebViewPackage/releases/tag/android) 下载包名为 `com.android.webview` 的 `arm64` APK，详见 [BUILD.md](BUILD.md)。

---

## v1.1 更新说明（重要修复）

相比 `v1.0` 仅做单文件 systemless 挂载，`v1.1` 修复了两个关键实测问题：

1. **修复勾选 Magisk 排除列表 / Shamiko 时应用内网页白屏**
   - **根因**：仅通过 Magisk 挂载覆盖 `/product/app/webview/webview.apk` 时，被加入排除列表（Shamiko 卸载模块挂载）的应用在自身命名空间内会退回读取原厂 **75**，而系统 `webview_zygote` 孵化的沙箱渲染进程 `sandboxed_process0` 仍运行 **134**，主进程与渲染进程跨代握手失败（`ChildProcessConnection.start failed`）导致白屏。
   - **解决**：模块挂载同签名 134 底包的同时，开机后由 `service.sh` 自动将 134 作为系统应用更新同步安装至 `/data/app/`（若已存在则跳过），并通过 `oat/.replace` 遮蔽原厂 75 的预编译目录。Shamiko 不会卸载 `/data/app/`，因此无论应用是否在排除列表中，宿主进程与沙箱进程均统一加载 `/data/app/` 下的 134，且不增加挂载痕迹。
2. **修复停用/移除模块后 PackageManager 记录卡在 134 的回滚撕裂问题**
   - **根因**：原厂 75 APK 出厂时间戳为 `2009-01-01`，早于刷入 134 时生成的 `/data/system/package_cache` 缓存时间，直接停用模块会导致系统沿用 134 缓存记录而物理文件变回 75。
   - **解决**：内置 `uninstall.sh` 与 `post-fs-data` 守卫脚本，停用或移除模块重启时会在 `system_server` 启动前自动清理 `/data/app` 更新副本及 `webview` 解析缓存，干净还原回原厂 `75.0.3770.156`。

---

## 为什么坚果 R2 需要这个模块

坚果 R2 的 Smartisan OS 将 WebView provider 白名单锁死在 `com.android.webview` 单一包名上：

- `framework-res.apk` 的 `res/xml/config_webview_packages.xml` 仅声明了 `com.android.webview`
- 开发者选项中无「WebView 实现」切换入口，即使安装新版 `com.google.android.webview` 也不会被系统启用
- 出厂内核停留在 Chromium 75（2019 年），遇到 `??=`（Chrome 85+）等现代 JS/CSS 语法直接报 `SyntaxError` 白屏或超时

本模块保持 `com.android.webview` 包名不变，以「systemless 同签名底座 + `/data/app` 更新副本」双层结构完成原地升级，无需改动 `framework-res.apk`，也不修改真实系统分区。

---

## 安装与升级

1. **前置建议**：备份 `boot` 分区，并确认开机长按音量下键可进入 Magisk 安全模式。
2. **刷入**：打开 **Magisk → 模块 → 从本地安装**，选择 `webview_upgrade_134_v1.1.zip`（已装 `v1.0` 的用户可直接刷入原地升级），点击**重启**。
3. **开机等待**：重启进入桌面后等待约 **15～30 秒**（首次开机 `service.sh` 会在后台完成 `/data/app` 同步安装，期间正在使用 WebView 的应用可能会刷新一次）。

## 验证命令

```sh
su -c "pm path com.android.webview && dumpsys webviewupdate | head -n 5"
```

期望输出：
- 路径指向 `/data/app/~~.../com.android.webview-.../base.apk`
- `Current WebView package (name, version): (com.android.webview, 134.0.6998.39)`

如需查看后台同步日志，可执行：
```sh
su -c "cat /data/adb/modules/webview_upgrade/service.log"
```

---

## 回滚原厂 75

在 Magisk 模块页直接**移除**（或停用）本模块并**重启手机**即可。守卫脚本会在开机早期自动清理 `/data/app` 更新副本与 `package_cache` 中的 WebView 缓存，重启后 `dumpsys webviewupdate` 即恢复为 `(com.android.webview, 75.0.3770.156)`。

> **日常使用提醒**：启用本模块期间，请保持 Magisk 中模块开关开启，**不要**在应用管理里对 Android System WebView 手动点击「卸载更新」。

---

## 已知说明与副作用

1. **系统自带浏览器搜索可能闪退**：锤子自带浏览器（`com.android.browser`）在 134 内核下搜索功能可能异常（社区已知现象），不影响 Chrome 及其他第三方浏览器，大爆炸、一步、闪念胶囊实测正常。
2. **如果使用了 HMA（隐藏应用列表）白名单模式**：请确保模板勾选了「排除系统应用」或将 `com.android.webview` 加入白名单，避免应用无法查询 WebView 包信息。

---

## 文件校验（v1.1）

```text
文件名 : webview_upgrade_134_v1.1.zip
大小   : 97,396,624 字节 (92.88 MB)
SHA256 : 954146e5f2252a90b6d36c177706cf9205a934a9ec6712494f58bb9a9c8244d7

内嵌 webview.apk (134.0.6998.39_min26_arm64.apk)
大小   : 206,597,006 字节
SHA256 : da886ba4b6ccb9883b8f88d2c999c58e6b15363faa7008c40be4bc1459ca341a
```

## 模块结构与来源致谢

```text
module.prop
customize.sh
service.sh
uninstall.sh
META-INF/com/google/android/update-binary
META-INF/com/google/android/updater-script
system/product/app/webview/oat/.replace
system/product/app/webview/webview.apk   (Release 包内提供，SHA256: da886ba4...ca341a)
README.txt
```

- 内嵌 APK 来自 [JonaNorman/WebViewPackage](https://github.com/JonaNorman/WebViewPackage/releases/tag/android)（AOSP 官方预编译件，AOSP `testkey` 签名 `32:A2:FC:74:...`，未做任何二进制修改）。
- 致谢酷安社区坚果 R1 / R2 机友的前期探索。
