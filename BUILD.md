# 如何自行构建模块包

本仓库仅保存模块的脚本与说明文件，不包含约 197 MB 的二进制 `webview.apk`。如需自行打包或替换为其他版本，请按以下步骤操作。

## 1. 仓库目录结构

```text
module.prop                                      模块描述信息
customize.sh                                     刷入时部署 oat 遮蔽与回滚守卫脚本
service.sh                                       开机自动将 WebView 同步安装至 /data/app
uninstall.sh                                     卸载模块时清理副本、缓存与守卫脚本
META-INF/com/google/android/update-binary        Magisk 标准安装入口
META-INF/com/google/android/updater-script       内容为 "#MAGISK"
system/product/app/webview/oat/.replace          遮蔽原厂 75 预编译 oat 目录
system/product/app/webview/webview.apk           ← 自行下载放入此处（仓库不包含）
README.txt                                       包内简要说明
```

## 2. 下载 WebView APK

前往 [JonaNorman/WebViewPackage (`android` tag)](https://github.com/JonaNorman/WebViewPackage/releases/tag/android) 下载：

- 默认使用版本：`134.0.6998.39_min26_arm64.apk`
- 预期 SHA256：`da886ba4b6ccb9883b8f88d2c999c58e6b15363faa7008c40be4bc1459ca341a`

如需更换该页面下的其他版本（如 `113`、`124`、`128` 等），请务必确认：

| 检查项 | 要求 |
|---|---|
| 包名 | 必须是 `com.android.webview`（`android` tag；不能用 `google` tag 的 `com.google.android.webview`） |
| 架构 | `arm64`（坚果 R2 为 `arm64-v8a`） |
| `minSdk` | 不高于 `30`（Android 11） |

## 3. 打包成 Magisk 模块 ZIP

所有脚本文件必须保持 **UTF-8 无 BOM + LF (`\n`) 换行符**（切勿转为 Windows `CRLF`）：

```sh
mkdir -p system/product/app/webview/oat
: > system/product/app/webview/oat/.replace
cp /path/to/134.0.6998.39_min26_arm64.apk system/product/app/webview/webview.apk

zip -r -9 webview_upgrade_134_v1.1.zip \
    module.prop \
    customize.sh \
    service.sh \
    uninstall.sh \
    README.txt \
    META-INF/ \
    system/
```

打包检查要点：
- `module.prop`、`customize.sh`、`service.sh`、`uninstall.sh`、`META-INF/`、`system/` 必须直接位于 **ZIP 根目录**（外层不能多套一层文件夹）。
- 所有 `.sh` 与 `update-binary` 换行符必须为 `LF`。
