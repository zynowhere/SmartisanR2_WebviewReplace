WebView 升级模块 v1.1 (com.android.webview 75 -> 134.0.6998.39)
===============================================================
适用：坚果 R2 / DT2002C (darwin)，Android 11 (SDK 30)，Magisk 20.4+

v1.1 更新重点
-------------
1. 解决 Magisk 排除列表 (DenyList) / Shamiko 下部分应用内嵌网页白屏问题：
   模块挂载 /product/app/webview/webview.apk 提供同签名底包，并在开机完成后由
   service.sh 自动将同一份 134 APK 作为系统应用更新同步安装至 /data/app/。
   Shamiko 卸载只读分区挂载时不会影响 /data/app/，宿主进程与沙箱渲染进程版本始终一致。
2. 新增 system/product/app/webview/oat/.replace，遮蔽原厂 75 遗留的预编译 oat 目录。
3. 新增 uninstall.sh 与 post-fs-data 回滚守卫脚本：在 Magisk 中停用或移除本模块并重启时，
   自动在 system_server 启动前清理 /data/app 更新副本与 package_cache 缓存，干净回退至 75，
   不再出现「物理文件 75 + 系统记录 134」撕裂现象。

安装与升级
----------
Magisk -> 模块 -> 从本地安装 -> 选择 webview_upgrade_134_v1.1.zip -> 重启。
(若已安装 v1.0，直接刷入即可原地覆盖升级，无需先卸载旧版。)

刷入重启后请等待开机完成约 15~30 秒（后台首次同步安装至 /data/app），随后验证：
  su -c "pm path com.android.webview"
  期望输出：package:/data/app/~~.../com.android.webview-.../base.apk
  su -c "dumpsys webviewupdate | head -n 5"
  期望输出：Current WebView package (name, version): (com.android.webview, 134.0.6998.39)
  (亦可查看模块运行日志：cat /data/adb/modules/webview_upgrade/service.log)

日常注意
--------
- 使用期间请保持 Magisk 中本模块处于开启状态，切勿在应用管理中对 WebView 点击「卸载更新」。
- 回滚原厂 75：直接在 Magisk 中停用或移除本模块，重启即可自动还原。
